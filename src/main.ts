import {vec3} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Square from './geometry/Square';
import Mesh from './geometry/Mesh';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import {readTextFile} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import Texture from './rendering/gl/Texture';
import Cloud from './Cloud';

// Define an object with application parameters and button callbacks
// const controls = {
//   // Extra credit: Add interactivity
// };

let square: Square;

// TODO: replace with your scene's stuff

let obj0: string;
let obj1: string;
let mesh0: Mesh;
let tex0: Texture;
let tex1: Texture;

let meshes : Mesh[];
let cloud : Cloud;


var timer = {
  deltaTime: 0.0,
  startTime: 0.0,
  currentTime: 0.0,
  updateTime: function() {
    var t = Date.now();
    t = (t - timer.startTime) * 0.001;
    timer.deltaTime = t - timer.currentTime;
    timer.currentTime = t;
  },
}


function loadOBJText() {
  obj0 = readTextFile('../resources/obj/cloud.obj')
  obj1 = readTextFile('../resources/obj/wahoo.obj')
}


function loadScene() {
  square && square.destroy();
  mesh0 && mesh0.destroy();

  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();

  mesh0 = new Mesh(obj0, vec3.fromValues(0, 0, 0));
  mesh0.create();

  meshes = new Array<Mesh>();

  let num = 0;
  let center1 = vec3.fromValues(10, 5, -10);
  let center2 = vec3.fromValues(3, 6, -20);
  let center3 = vec3.fromValues(-9, 6, -15);
  let center4 = vec3.fromValues(-15, 4, -10);
  let center5 = vec3.fromValues(0, 8, -20);

  // for(let i = 0; i < 8; i++) {
  //   for(let j = 0; j < 8; j++) {
  //     meshes.push(new Mesh(obj0,
  //        vec3.fromValues(
  //         Math.random() * 5.0 + center1[0],
  //         Math.random() * 3.0 + center1[1],
  //         Math.random() * 5.0 + center1[2]
  //       )));
  //     meshes[i * 8 + j].create();
  //   }
  // }

  // num = meshes.length;

  // for(let i = 0; i < 8; i++) {
  //   for(let j = 0; j < 8; j++) {
  //     meshes.push(new Mesh(obj0,
  //        vec3.fromValues(
  //         Math.random() * 4.0 + center2[0],
  //         Math.random() * 2.0 + center2[1],
  //         Math.random() * 4.0 + center2[2]
  //       )));
  //     meshes[i * 8 + j + num].create();
  //   }
  // }

  // num = meshes.length;

  // for(let i = 0; i < 8; i++) {
  //   for(let j = 0; j < 8; j++) {
  //     meshes.push(new Mesh(obj0,
  //        vec3.fromValues(
  //         Math.random() * 4.0 + center3[0],
  //         Math.random() * 5.0 + center3[1],
  //         Math.random() * 6.0 + center3[2]
  //       )));
  //     meshes[i * 8 + j + num].create();
  //   }
  // }

  // num = meshes.length;

  // for(let i = 0; i < 15; i++) {
  //   for(let j = 0; j < 15; j++) {
  //     meshes.push(new Mesh(obj0,
  //        vec3.fromValues(
  //         Math.random() * 6.0 + center4[0],
  //         Math.random() * 3.0 + center4[1],
  //         Math.random() * 7.0 + center4[2]
  //       )));
  //     meshes[i * 15 + j + num].create();
  //   }
  // }


  cloud = new Cloud(vec3.fromValues(0,0,0), vec3.fromValues(10,3,10), vec3.fromValues(0,0,0), 5);
  cloud.create();


  tex0 = new Texture('../resources/textures/noiset.png');
  tex1 = new Texture('../resources/textures/uniform-noise.jpg');
}


function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  // const gui = new DAT.GUI();

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 9, 25), vec3.fromValues(0, 9, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0, 0, 0, 1);
  gl.enable(gl.DEPTH_TEST);

  const standardDeferred = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/standard-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/standard-frag.glsl')),
    ]);

  standardDeferred.setupTexUnits(["tex_Color"]);

  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    timer.updateTime();
    renderer.updateTime(timer.deltaTime, timer.currentTime);

    standardDeferred.bindTexToUnit("tex_Color", tex0, 0);

    renderer.clear();
    renderer.clearGB();

    // TODO: pass any arguments you may need for shader passes
    // forward render mesh info into gbuffers
    renderer.renderToGBuffer(camera, standardDeferred, []);
    // render from gbuffers into 32-bit color buffer
    renderer.renderFromGBuffer(camera);


    renderer.renderCloudLayer(tex1, camera);



    // apply 32-bit post and tonemap from 32-bit color to 8-bit color
    renderer.renderPostProcessHDR();
    // apply 8-bit post and draw
    renderer.renderPostProcessLDR();

    stats.end();
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}


function setup() {
  timer.startTime = Date.now();
  loadOBJText();
  main();
}

setup();
