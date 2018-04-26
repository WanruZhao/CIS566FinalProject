import {vec2, mat4, vec4, vec3} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram, {Shader} from './ShaderProgram';
import PostProcess from './PostProcess'
import Square from '../../geometry/Square';
import { Texture } from './Texture';
import { getPackedSettings } from 'http2';
// import { normalize } from 'gl-matrix/src/gl-matrix/vec2';
const ssaoKernel : Array<number> = [];

class OpenGLRenderer {
  gBuffer: WebGLFramebuffer; // framebuffer for deferred rendering

  gbTargets: WebGLTexture[]; // references to different 4-channel outputs of the gbuffer
                             // Note that the constructor of OpenGLRenderer initializes
                             // gbTargets[0] to store 32-bit values, while the rest
                             // of the array stores 8-bit values. You can modify
                             // this if you want more 32-bit storage.
  gbNoiseTexture: WebGLTexture;
  depthTexture: WebGLTexture; // You don't need to interact with this, it's just
                              // so the OpenGL pipeline can do depth sorting


  // shadowmapTexture:   WebGLTexture; 
  // shadowmapBuffer:   WebGLFramebuffer;                  

  // post-processing buffers pre-tonemapping (32-bit color)
  post32Buffers: WebGLFramebuffer[];
  post32Targets: WebGLTexture[];

  // post-processing buffers post-tonemapping (8-bit color)
  post8Buffers: WebGLFramebuffer[];
  post8Targets: WebGLTexture[];

  // post processing shader lists, try to limit the number for performance reasons
  post8Passes: PostProcess[];
  post32Passes: PostProcess[];

  currentTime: number; // timer number to apply to all drawing shaders

  waterTex1 : Texture = new Texture('../resources/textures/water1.jpg');
  waterTex2 : Texture = new Texture('../resources/textures/water2.jpg');
  waterTex3 : Texture = new Texture('../resources/textures/water2.jpg');

  // the shader that renders from the gbuffers into the postbuffers
  deferredShader :  PostProcess = new PostProcess(
    new Shader(gl.FRAGMENT_SHADER, require('../../shaders/deferred-render.glsl'))
    );

  // shader that maps 32-bit color to 8-bit color
  tonemapPass : PostProcess = new PostProcess(
    new Shader(gl.FRAGMENT_SHADER, require('../../shaders/tonemap-frag.glsl'))
    );

  // depthmapPass : PostProcess = new PostProcess(
  //   new Shader(gl.FRAGMENT_SHADER, require('../../shaders/depth-frag.glsl'))
  //   );

  cloudPass : PostProcess = new PostProcess(
    new Shader(gl.FRAGMENT_SHADER, require('../../shaders/cloud-frag.glsl'))
  );

  copyPass : PostProcess = new PostProcess(
    new Shader(gl.FRAGMENT_SHADER, require('../../shaders/copy-frag.glsl'))
  );

  blurPass : PostProcess = new PostProcess(
    new Shader(gl.FRAGMENT_SHADER, require('../../shaders/blur-frag.glsl'))
  );

  add8BitPass(pass: PostProcess) {
    this.post8Passes.push(pass);
  }


  add32BitPass(pass: PostProcess) {
    this.post32Passes.push(pass);
  }

  


  constructor(public canvas: HTMLCanvasElement) {
    this.currentTime = 0.0;
    this.gbTargets = [undefined, undefined, undefined];
    this.post8Buffers = [undefined, undefined];
    this.post8Targets = [undefined, undefined];
    this.post8Passes = [];

    this.post32Buffers = [undefined, undefined];
    this.post32Targets = [undefined, undefined];
    this.post32Passes = [];

    // TODO: these are placeholder post shaders, replace them with something good
    // this.add8BitPass(new PostProcess(new Shader(gl.FRAGMENT_SHADER, require('../../shaders/examplePost-frag.glsl'))));
    // this.add8BitPass(new PostProcess(new Shader(gl.FRAGMENT_SHADER, require('../../shaders/examplePost2-frag.glsl'))));

    // this.add32BitPass(new PostProcess(new Shader(gl.FRAGMENT_SHADER, require('../../shaders/cloud-frag.glsl'))));

    if (!gl.getExtension("OES_texture_float_linear")) {
      console.error("OES_texture_float_linear not available");
    }

    if (!gl.getExtension("EXT_color_buffer_float")) {
      console.error("FLOAT color buffer not available");
    }

    var gb0loc = gl.getUniformLocation(this.deferredShader.prog, "u_gb0");
    var gb1loc = gl.getUniformLocation(this.deferredShader.prog, "u_gb1");
    var gb2loc = gl.getUniformLocation(this.deferredShader.prog, "u_gb2");
    var gbNoise = gl.getUniformLocation(this.deferredShader.prog, "u_SSAONoise");
    this.deferredShader.setupTexUnits(["u_Water1"]);
    this.deferredShader.setupTexUnits(["u_Water2"]);
    this.deferredShader.setupTexUnits(["a"]);

    this.deferredShader.use();
    gl.uniform1i(gb0loc, 0);
    gl.uniform1i(gb1loc, 1);
    gl.uniform1i(gb2loc, 2);
    gl.uniform1i(gbNoise, 3);
    
    for( let i = 0; i < 64; ++i)
    {
      let ssaoSample = vec3.fromValues(Math.random() * 2.0 - 1.0,
                                       Math.random() * 2.0 - 1.0,
                                       Math.random());
      let a = Math.random() * 2.0 - 1.0;
      let b = Math.random() * 2.0 - 1.0;
      let c = Math.random();                         
      let  l = Math.sqrt(a*a + b*b + c*c);  
      let temp = Math.random(); 
      a = a * temp / l;
      b = b * temp / l;
      c = c * temp / l;                                            
      let ssaoScale = i * 1.0 / 64.0;
      ssaoScale = 0.1 + ssaoScale * ssaoScale * (1.0 - 0.1);
      a = a * ssaoScale;
      b = b * ssaoScale;
      c = c * ssaoScale;
      ssaoKernel.push(ssaoScale);
      ssaoKernel.push(b);
      ssaoKernel.push(c);
    }
  }


  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }


  setSize(width: number, height: number) {
    console.log(width, height);
    this.canvas.width = width;
    this.canvas.height = height;

    // --- GBUFFER CREATION START ---
    // refresh the gbuffers
    this.gBuffer = gl.createFramebuffer();
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.gBuffer);
    gl.drawBuffers([gl.COLOR_ATTACHMENT0, gl.COLOR_ATTACHMENT1, gl.COLOR_ATTACHMENT2]);

    for (let i = 0; i < this.gbTargets.length; i ++) {
      this.gbTargets[i] = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, this.gbTargets[i]);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

      if (i == 2) {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, gl.drawingBufferWidth, gl.drawingBufferHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
      }
      else {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, gl.drawingBufferWidth, gl.drawingBufferHeight, 0, gl.RGBA, gl.FLOAT, null);
      }

      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0 + i, gl.TEXTURE_2D, this.gbTargets[i], 0);
    }


    // SSAO Noise texture
    
   let ssaoNoiseData: Array<number> = [];
    for(let i = 0; i < 16; i++){
      // let noise = vec3.fromValues(Math.random() * 2.0 - 1.0,
      //                             Math.random() * 2.0 - 1.0,
      //                             0.0);
      ssaoNoiseData.push(Math.random() * 2.0 - 1.0);
      ssaoNoiseData.push(Math.random() * 2.0 - 1.0);
      ssaoNoiseData.push(0.0);
    }   
    const ssaoNoise = new Float32Array(ssaoNoiseData);
    this.gbNoiseTexture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, this.gbNoiseTexture);
    gl.pixelStorei(gl.UNPACK_ALIGNMENT, 1);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB16F, 4, 4, 0, gl.RGB, gl.FLOAT,ssaoNoise);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
  
    // new texture
    this.deferredShader.bindTexToUnit("u_Water1", this.waterTex1, 4);
    this.deferredShader.bindTexToUnit("u_Water2", this.waterTex2, 5);
    this.deferredShader.bindTexToUnit("a", this.waterTex3, 6);

    // // shadow map texture
    // this.shadowmapTexture = gl.createTexture();
    // gl.bindTexture(gl.TEXTURE_2D, this.shadowmapTexture);
    // // glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, SHADOW_WIDTH, SHADOW_HEIGHT, 0, GL_DEPTH_COMPONENT, GL_FLOAT, NULL);
    // gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1024, 1024, 0,gl.RGBA, gl.UNSIGNED_BYTE, null);
    // gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    // gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

    // depth attachment
    this.depthTexture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, this.depthTexture);
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.DEPTH_COMPONENT32F, gl.drawingBufferWidth, gl.drawingBufferHeight, 0, gl.DEPTH_COMPONENT, gl.FLOAT, null);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, this.depthTexture, 0);

    var FBOstatus = gl.checkFramebufferStatus(gl.FRAMEBUFFER);
    if (FBOstatus != gl.FRAMEBUFFER_COMPLETE) {
        console.error("GL_FRAMEBUFFER_COMPLETE failed, CANNOT use FBO[0]\n");
    }

    gl.bindFramebuffer(gl.FRAMEBUFFER, null);

    // // create shadowmap buffer
    // this.shadowmapBuffer = gl.createFramebuffer();
    // gl.bindRenderbuffer(gl.RENDERBUFFER, this.shadowmapBuffer);
    // gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, 1024, 1024);
    // gl.framebufferTexture2D(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, this.shadowmapTexture, 0);
    // gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, this.shadowmapBuffer);
    // gl.bindTexture(gl.TEXTURE_2D, null);
    // gl.bindRenderbuffer(gl.RENDERBUFFER, null);


    // create the framebuffers for post processing
    for (let i = 0; i < this.post8Buffers.length; i++) {

      // 8 bit buffers have unsigned byte textures of type gl.RGBA8
      this.post8Buffers[i] = gl.createFramebuffer()
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.post8Buffers[i]);
      gl.drawBuffers([gl.COLOR_ATTACHMENT0]);

      this.post8Targets[i] = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, this.post8Targets[i]);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, gl.drawingBufferWidth, gl.drawingBufferHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, this.post8Targets[i], 0);

      FBOstatus = gl.checkFramebufferStatus(gl.FRAMEBUFFER);
      if (FBOstatus != gl.FRAMEBUFFER_COMPLETE) {
        console.error("GL_FRAMEBUFFER_COMPLETE failed, CANNOT use 8 bit FBO\n");
      }

      // 32 bit buffers have float textures of type gl.RGBA32F
      this.post32Buffers[i] = gl.createFramebuffer()
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.post32Buffers[i]);
      gl.drawBuffers([gl.COLOR_ATTACHMENT0]);

      this.post32Targets[i] = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, this.post32Targets[i]);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, gl.drawingBufferWidth, gl.drawingBufferHeight, 0, gl.RGBA, gl.FLOAT, null);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, this.post32Targets[i], 0);

      FBOstatus = gl.checkFramebufferStatus(gl.FRAMEBUFFER);
      if (FBOstatus != gl.FRAMEBUFFER_COMPLETE) {
        console.error("GL_FRAMEBUFFER_COMPLETE failed, CANNOT use 8 bit FBO\n");
      }
    }

    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindTexture(gl.TEXTURE_2D, null);
  }


  updateTime(deltaTime: number, currentTime: number) {
    this.deferredShader.setTime(currentTime);
    for (let pass of this.post8Passes) pass.setTime(currentTime);
    for (let pass of this.post32Passes) pass.setTime(currentTime);
    this.currentTime = currentTime;
  }


  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }


  clearGB() {
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.gBuffer);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
  }


  renderToGBuffer(camera: Camera, gbProg: ShaderProgram, drawables: Array<Drawable>) {
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.gBuffer);
    gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
    gl.enable(gl.DEPTH_TEST);
    // gl.disable(gl.DEPTH_TEST);
    // gl.enable(gl.BLEND);
    // gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    let model = mat4.create();
    let viewProj = mat4.create();
    let view = camera.viewMatrix;
    let proj = camera.projectionMatrix;
    let color = vec4.fromValues(0.5, 0.5, 0.5, 1);

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    gbProg.setModelMatrix(model);
    gbProg.setViewProjMatrix(viewProj);
    gbProg.setGeometryColor(color);
    gbProg.setViewMatrix(view);
    gbProg.setProjMatrix(proj);

    gbProg.setTime(this.currentTime);
    
    for (let drawable of drawables) {

      let a = vec3.fromValues(drawable.center[0], drawable.center[1], drawable.center[2]);
      let inType = drawable.type;
      gbProg.setCenter(a);
      gbProg.setType(inType);
      gbProg.draw(drawable);
    }

    gl.bindFramebuffer(gl.FRAMEBUFFER, null);

  }

  renderFromGBuffer(camera: Camera) {
    // gl.bindFramebuffer(gl.FRAMEBUFFER, this.post32Buffers[0]);
    gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
    gl.disable(gl.DEPTH_TEST);
    gl.enable(gl.BLEND);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    let view = camera.viewMatrix;
    let proj = camera.projectionMatrix;
    this.deferredShader.setViewMatrix(view);
    this.deferredShader.setProjMatrix(proj);
    this.deferredShader.setDimension(vec2.fromValues(this.canvas.width, this.canvas.height));
    this.deferredShader.setSSAOSamples(ssaoKernel);
    // this.deferredShader.setShadowMVMatrix();

        // new texture
        // this.deferredShader.bindTexToUnit("u_Water1", this.waterTex1, 5);
        // this.deferredShader.bindTexToUnit("u_Water2", this.waterTex2, 6);
    
    for (let i = 0; i < this.gbTargets.length; i ++) {
      gl.activeTexture(gl.TEXTURE0 + i);
      gl.bindTexture(gl.TEXTURE_2D, this.gbTargets[i]);
    }
    
    gl.activeTexture(gl.TEXTURE3);
    gl.bindTexture(gl.TEXTURE_2D, this.gbNoiseTexture);

    this.deferredShader.draw();
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
  }

  // renderDepthMap(cam: Camera)
  // {
  //   // gl.bindFramebuffer(gl.FRAMEBUFFER, this.post32Buffers[1]);
  //   // texture
  //   // gl.bindTexture(gl.TEXTURE_2D, this.post32Targets[0]);

  //   let view = cam.viewMatrix;
  //   let proj = cam.projectionMatrix;
  //   this.depthmapPass.setViewMatrix(view);
  //   this.depthmapPass.setProjMatrix(proj);

  // }

  renderCloudLayer(texture : Texture, cam : Camera) {
    gl.bindFramebuffer(gl.FRAMEBUFFER, this.post32Buffers[1]);
    gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
    gl.disable(gl.DEPTH_TEST);
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    // this.cloudPass.bindTexToUnit("u_frame", texture, 0);
    gl.activeTexture(gl.TEXTURE0);
    texture.bindTex();

    this.cloudPass.setTime(this.currentTime);
    this.cloudPass.setDimension(vec2.fromValues(this.canvas.width, this.canvas.height));
    this.cloudPass.setFar(cam.far);
    this.cloudPass.setEye(vec4.fromValues(cam.position[0], cam.position[1], cam.position[2], 1.0));
    this.cloudPass.draw();

    gl.bindFramebuffer(gl.FRAMEBUFFER, null);


    gl.bindFramebuffer(gl.FRAMEBUFFER, this.post32Buffers[0]);
    gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
    gl.disable(gl.DEPTH_TEST);
    gl.enable(gl.BLEND);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, this.post32Targets[1]);
    this.copyPass.setDimension(vec2.fromValues(this.canvas.width, this.canvas.height));
    this.copyPass.draw();
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);


  }


  // TODO: pass any info you need as args
  renderPostProcessHDR() {
    // TODO: replace this with your post 32-bit pipeline
    // the loop shows how to swap between frame buffers and textures given a list of processes,
    // but specific shaders (e.g. bloom) need specific info as textures
    let i = 0;
    for (i = 0; i < this.post32Passes.length; i++){
      // Pingpong framebuffers for each pass.
      // In other words, repeatedly flip between storing the output of the
      // current post-process pass in post32Buffers[1] and post32Buffers[0].
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.post32Buffers[(i + 1) % 2]);

      gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
      gl.disable(gl.DEPTH_TEST);
      gl.enable(gl.BLEND);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

      // Recall that each frame buffer is associated with a texture that stores
      // the output of a render pass. post32Targets is the array that stores
      // these textures, so we alternate reading from the 0th and 1th textures
      // each frame (the texture we wrote to in our previous render pass).
      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, this.post32Targets[(i) % 2]);

      this.post32Passes[i].setTime(this.currentTime);
      this.post32Passes[i].setDimension(vec2.fromValues(this.canvas.width, this.canvas.height));
      this.post32Passes[i].draw();

      // bind default frame buffer
      gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    }

    // apply tonemapping
    // TODO: if you significantly change your framework, ensure this doesn't cause bugs!
    // render to the first 8 bit buffer if there is more post, else default buffer
    if (this.post8Passes.length > 0) {
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.post8Buffers[0]);
    }
    else {
      gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    }

    gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);

    gl.disable(gl.DEPTH_TEST);
    gl.enable(gl.BLEND);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    gl.activeTexture(gl.TEXTURE0);
    // bound texture is the last one processed before

    gl.bindTexture(gl.TEXTURE_2D, this.post32Targets[Math.max(0, i) % 2]);

    this.tonemapPass.draw();

  }


  // TODO: pass any info you need as args
  renderPostProcessLDR() {
    // TODO: replace this with your post 8-bit pipeline
    // the loop shows how to swap between frame buffers and textures given a list of processes,
    // but specific shaders (e.g. motion blur) need specific info as textures
    for (let i = 0; i < this.post8Passes.length; i++){
      // pingpong framebuffers for each pass
      // if this is the last pass, default is bound
      if (i < this.post8Passes.length - 1) gl.bindFramebuffer(gl.FRAMEBUFFER, this.post8Buffers[(i + 1) % 2]);
      else gl.bindFramebuffer(gl.FRAMEBUFFER, null);

      gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
      gl.disable(gl.DEPTH_TEST);
      gl.enable(gl.BLEND);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, this.post8Targets[(i) % 2]);

      this.post8Passes[i].draw();

      // bind default
      gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    }
  }

};

export default OpenGLRenderer;
