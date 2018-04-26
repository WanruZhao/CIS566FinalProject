import { vec4 } from 'gl-matrix';
import Drawable from '../rendering/gl/Drawable';
import { gl } from '../globals';
class Terrian extends Drawable {
    constructor(center, inType) {
        super();
        this.center = vec4.fromValues(center[0], center[1], center[2], 1);
        this.type = inType;
    }
    create() {
        this.indices = new Uint32Array([0, 1, 2,
            0, 2, 3,
            2, 3, 5,
            3, 4, 5]);
        this.normals = new Float32Array([0, 1, 0, 0,
            0, 1, 0, 0,
            0, 1, 0, 0,
            0, 1, 0, 0,
            0, 1, 0, 0,
            0, 1, 0, 0]);
        this.positions = new Float32Array([5, 0, 5, 1,
            5, 0, -5, 1,
            0, 0, -5, 1,
            0, 0, 5, 1,
            -5, 0, 5, 1,
            -5, 0, -5, 1]);
        this.colors = new Float32Array([1.0, 0.5, 0.5, 1.0,
            1.0, 0.5, 0.5, 1.0,
            1.0, 0.5, 0.5, 1.0,
            1.0, 0.5, 0.5, 1.0,
            1.0, 0.5, 0.5, 1.0,
            1.0, 0.5, 0.5, 1.0
        ]);
        this.uvs = new Float32Array([0, 0,
            1, 0,
            1, 0.5,
            0, 0.5,
            0, 1,
            1, 1]);
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
        console.log('Create Terrain');
    }
}
export default Terrian;
//# sourceMappingURL=Terrian.js.map