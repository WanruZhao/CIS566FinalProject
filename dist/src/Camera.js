import * as CameraControls from '3d-view-controls';
import { vec3, mat4 } from 'gl-matrix';
class Camera {
    constructor(position, target) {
        this.projectionMatrix = mat4.create();
        this.viewMatrix = mat4.create();
        this.fovy = 45 * 3.1415962 / 180.0;
        this.aspectRatio = 1;
        this.near = 0.1;
        this.far = 100;
        this.position = vec3.create();
        this.direction = vec3.create();
        this.target = vec3.create();
        this.up = vec3.create();
        this.controls = CameraControls(document.getElementById('canvas'), {
            eye: position,
            center: target,
        });
        this.controls.mode = 'turntable';
        vec3.add(this.target, this.position, this.direction);
        mat4.lookAt(this.viewMatrix, this.controls.eye, this.controls.center, this.controls.up);
    }
    setAspectRatio(aspectRatio) {
        this.aspectRatio = aspectRatio;
    }
    updateProjectionMatrix() {
        mat4.perspective(this.projectionMatrix, this.fovy, this.aspectRatio, this.near, this.far);
    }
    update() {
        this.controls.tick();
        vec3.add(this.target, this.position, this.direction);
        mat4.lookAt(this.viewMatrix, this.controls.eye, this.controls.center, this.controls.up);
    }
}
;
export default Camera;
//# sourceMappingURL=Camera.js.map