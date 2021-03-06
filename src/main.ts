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
import Terrian from './geometry/Terrian';


// Define an object with application parameters and button callbacks
// const controls = {
//   // Extra credit: Add interactivity
// };

let square: Square;
// TODO: replace with your scene's stuff

let obj0: string;
let myTerrian: string;

let fishes: Mesh[];

let mesh0: Mesh;
let terrian: Mesh;

let tex0: Texture;
let tex1: Texture;
let waterTex1: Texture;
let waterTex2: Texture;
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
  obj0 = readTextFile('./resources/obj/fish4.obj')
  myTerrian = readTextFile('./resources/obj/terrian.obj')
}


function loadScene() {
  square && square.destroy();
  mesh0 && mesh0.destroy();
  
  // square = new Square(vec3.fromValues(0, 0, 0));
  // square.create();

  fishes = new Array<Mesh>();
  
  // fishes.push(new Mesh(obj0, vec3.fromValues(5.0, 0.0, 0.0), 0));
  for( let i = 0; i < 20; ++i)
  {

    mesh0 = new Mesh(obj0, vec3.fromValues(i * 5 + (2.0 * Math.random()- 1.0), (2.0 * Math.random() - 1.0) * 3, 5.0 + 2.0 * Math.random() - 1.0), 0);
    mesh0.create();
    fishes.push(mesh0);
  }

  // terrian = new Mesh(myTerrian, vec3.fromValues(0, 0, 0), 1);
  // terrian.create();
  // fishes.push(terrian);


  cloud = new Cloud(vec3.fromValues(0,0,0), vec3.fromValues(10,3,10), vec3.fromValues(0,0,0), 5);
  cloud.create();


  // tex0 = new Texture('../resources/textures/noiset.png');

  tex1 = new Texture('./resources/textures/uniform-noise.jpg');

  tex0 = new Texture('./resources/obj/hujing.jpg');
  // tex0 = new Texture('../resources/textures/perlinnoise.png');

  //  tex1 = new Texture('../resources/textures/perlinnoise.png');

  // noiseTex = new Texture('../resources/obj/perlinnoise.png');
   waterTex1 = new Texture('./resources/textures/water3.png');
   waterTex2 = new Texture('./resources/textures/water2.jpg');

}

function loadMusic() {
  var audio = document.createElement("audio");
  audio.src = "./music/fish.mp3";
  audio.setAttribute('loop', "loop");
  audio.play();
}


function main() {

  loadMusic();

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

  const camera = new Camera(vec3.fromValues(20, -10, 20), vec3.fromValues(0, 10, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(1.0, 1.0, 1.0, 1);
  gl.enable(gl.DEPTH_TEST);

  const standardDeferred = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/standard-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/standard-frag.glsl')),
    ]);

  standardDeferred.setupTexUnits(["tex_Color"]);
  standardDeferred.setupTexUnits(["tex_Noise"]);

  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    timer.updateTime();
    renderer.updateTime(timer.deltaTime, timer.currentTime);

    standardDeferred.bindTexToUnit("tex_Color", tex0, 0);
    standardDeferred.bindTexToUnit("tex_Noise", tex1, 1);
    renderer.clear();
    renderer.clearGB();

    // TODO: pass any arguments you may need for shader passes
    // forward render mesh info into gbuffers


    renderer.renderToGBuffer(camera, standardDeferred, fishes);

    // renderer.renderToGBuffer(camera, standardDeferred, [mesh0, terrian]);


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
