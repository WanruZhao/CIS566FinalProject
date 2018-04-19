import {vec3, vec4, vec2} from 'gl-matrix';
import Drawable from './rendering/gl/Drawable';
import {gl} from './globals';
import * as Loader from 'webgl-obj-loader';
import Mesh from './geometry/Mesh';

class Cloud extends Drawable
{
    indices: Uint32Array;
    positions: Float32Array;
    normals: Float32Array;
    colors: Float32Array;
    uvs: Float32Array;
    center: vec4;
    scale: vec4;
    rotation: vec4;

    pos : Array<vec4>;
    col : Array<vec4>;
    uv : Array<vec2>;


    constructor(center : vec3, scale : vec3, rot : vec3, layer : number) {
        super();
        this.center = vec4.fromValues(center[0], center[1], center[2], 1.0);
        this.scale = vec4.fromValues(scale[0], scale[1], scale[2], 1.0);
        this.rotation = vec4.fromValues(rot[0], rot[1], rot[2], 1.0);

        this.pos = new Array<vec4>();
        this.col = new Array<vec4>();
        this.uv = new Array<vec2>();
        this.buildLayer(layer);
    }
    
    buildLayer(layer : number) {
        let step = 0.1; //2.0 * this.scale[1]/ layer;
        let step1 = 1.0 / layer;
        let h = this.scale[1];
        let w = this.scale[0];
        let d = this.scale[2];
        step1 = 0.2;
        for(let i = 0; i < layer; i++) {
            this.pos.push(vec4.fromValues(-w, -h + i * step, -d, 1));
            this.pos.push(vec4.fromValues(w, -h + i * step, -d, 1));
            this.pos.push(vec4.fromValues(w, -h + i * step, d, 1));
            this.pos.push(vec4.fromValues(-w, -h + i * step, d, 1));

            this.col.push(vec4.fromValues(0.8, 0.8, 0.8, step1));
            this.col.push(vec4.fromValues(0.8, 0.8, 0.8, step1));
            this.col.push(vec4.fromValues(0.8, 0.8, 0.8, step1));
            this.col.push(vec4.fromValues(0.8, 0.8, 0.8, step1));

            // this.uv.push(vec2.fromValues(step1 * i, step1 * (i + 1)));
            // this.uv.push(vec2.fromValues(step1 * (i + 1), step1 * (i + 1)));
            // this.uv.push(vec2.fromValues(step1 * (i + 1), step1 * i));
            // this.uv.push(vec2.fromValues(step1 * i, step1 * i));

            this.uv.push(vec2.fromValues(0, 1));
            this.uv.push(vec2.fromValues(1, 1));
            this.uv.push(vec2.fromValues(1, 0));
            this.uv.push(vec2.fromValues(0, 0));
        }

        this.pos.push(vec4.fromValues(-w, -h - 0.1, -d, 1));
        this.pos.push(vec4.fromValues(w, -h - 0.1, -d, 1));
        this.pos.push(vec4.fromValues(w, -h - 0.1, d, 1));
        this.pos.push(vec4.fromValues(-w, -h - 0.1, d, 1));

        this.col.push(vec4.fromValues(0.8, 0.8, 0.8, 1.0));
        this.col.push(vec4.fromValues(0.8, 0.8, 0.8, 1.0));
        this.col.push(vec4.fromValues(0.8, 0.8, 0.8, 1.0));
        this.col.push(vec4.fromValues(0.8, 0.8, 0.8, 1.0));

        // this.uv.push(vec2.fromValues(step1 * i, step1 * (i + 1)));
        // this.uv.push(vec2.fromValues(step1 * (i + 1), step1 * (i + 1)));
        // this.uv.push(vec2.fromValues(step1 * (i + 1), step1 * i));
        // this.uv.push(vec2.fromValues(step1 * i, step1 * i));

        this.uv.push(vec2.fromValues(0, 1));
        this.uv.push(vec2.fromValues(1, 1));
        this.uv.push(vec2.fromValues(1, 0));
        this.uv.push(vec2.fromValues(0, 0));
    }
    

    create() {
        let num = this.pos.length;

        this.positions = new Float32Array(4 * num);
        this.normals = new Float32Array(4 * num);
        this.indices = new Uint32Array(num / 4.0 * 6.0);
        this.colors = new Float32Array(4 * num);
        this.uvs = new Float32Array(2 * num);

        for(let i = 0; i < num; i++) {
            this.positions[4 * i] = this.pos[i][0];
            this.positions[4 * i + 1] = this.pos[i][1];
            this.positions[4 * i + 2] = this.pos[i][2];
            this.positions[4 * i + 3] = this.pos[i][3];

            this.normals[4 * i] = 0.0;
            this.normals[4 * i + 1] = 1.0;
            this.normals[4 * i + 2] = 0.0;
            this.normals[4 * i + 3] = 0.0;

            this.colors[4 * i] = this.col[i][0];
            this.colors[4 * i + 1] = this.col[i][1];
            this.colors[4 * i + 2] = this.col[i][2];
            this.colors[4 * i + 3] = this.col[i][3];

            this.uvs[2 * i] = this.uv[i][0];
            this.uvs[2 * i + 1] = this.uv[i][1];
        }

        for(let i = 0; i < num / 4.0; i++) {
            this.indices[6 * i] = 4 * i;
            this.indices[6 * i + 1] = 4 * i + 1;
            this.indices[6 * i + 2] = 4 * i + 2;
            this.indices[6 * i + 3] = 4 * i + 0;
            this.indices[6 * i + 4] = 4 * i + 2;
            this.indices[6 * i + 5] = 4 * i + 3;
        }

        this.generateIdx();
        this.generatePos();
        this.generateNor();
        this.generateUV();
        this.generateCol();

        this.count = this.indices.length;
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.indices, gl.STATIC_DRAW);
    
        gl.bindBuffer(gl.ARRAY_BUFFER, this.bufNor);
        gl.bufferData(gl.ARRAY_BUFFER, this.normals, gl.STATIC_DRAW);
    
        gl.bindBuffer(gl.ARRAY_BUFFER, this.bufPos);
        gl.bufferData(gl.ARRAY_BUFFER, this.positions, gl.STATIC_DRAW);
    
        gl.bindBuffer(gl.ARRAY_BUFFER, this.bufCol);
        gl.bufferData(gl.ARRAY_BUFFER, this.colors, gl.STATIC_DRAW);
    
    
        gl.bindBuffer(gl.ARRAY_BUFFER, this.bufUV);
        gl.bufferData(gl.ARRAY_BUFFER, this.uvs, gl.STATIC_DRAW);

        console.log('create cloud');


    }
}

export default Cloud;