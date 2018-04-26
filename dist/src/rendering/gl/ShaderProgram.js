import { mat4 } from 'gl-matrix';
import { gl } from '../../globals';
var activeProgram = null;
export class Shader {
    constructor(type, source) {
        this.shader = gl.createShader(type);
        gl.shaderSource(this.shader, source);
        gl.compileShader(this.shader);
        if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
            throw gl.getShaderInfoLog(this.shader);
        }
    }
}
;
class ShaderProgram {
    constructor(shaders) {
        this.prog = gl.createProgram();
        for (let shader of shaders) {
            gl.attachShader(this.prog, shader.shader);
        }
        gl.linkProgram(this.prog);
        if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
            throw gl.getProgramInfoLog(this.prog);
        }
        this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
        this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
        this.attrCol = gl.getAttribLocation(this.prog, "vs_Col");
        this.attrUV = gl.getAttribLocation(this.prog, "vs_UV");
        this.unifModel = gl.getUniformLocation(this.prog, "u_Model");
        this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
        this.unifViewProj = gl.getUniformLocation(this.prog, "u_ViewProj");
        this.unifViewProjInv = gl.getUniformLocation(this.prog, "u_ViewProjInv");
        this.unifView = gl.getUniformLocation(this.prog, "u_View");
        this.unifProj = gl.getUniformLocation(this.prog, "u_Proj");
        this.unifColor = gl.getUniformLocation(this.prog, "u_Color");
        this.unifTime = gl.getUniformLocation(this.prog, "u_Time");
        this.unifViewInv = gl.getUniformLocation(this.prog, "u_ViewInv");
        this.unifDimension = gl.getUniformLocation(this.prog, "u_Dimension");
        this.unifFar = gl.getUniformLocation(this.prog, "u_Far");
        this.unifEye = gl.getUniformLocation(this.prog, "u_Eye");
        this.unifCenter = gl.getUniformLocation(this.prog, "u_Center");
        this.unifType = gl.getUniformLocation(this.prog, "u_Type");
        this.unifSSAOSamples = gl.getUniformLocation(this.prog, "u_Samples");
        this.unifShadowPMatrix = gl.getUniformLocation(this.prog, "u_PMatrix");
        this.unifShadowMVMatrix = gl.getUniformLocation(this.prog, "u_MVMatrix");
        this.unifLightP = gl.getUniformLocation(this.prog, "u_LightP");
        this.unifLightV = gl.getUniformLocation(this.prog, "u_LightV");
        this.unifTexUnits = new Map();
    }
    setupTexUnits(handleNames) {
        for (let handle of handleNames) {
            var location = gl.getUniformLocation(this.prog, handle);
            if (location !== -1) {
                this.unifTexUnits.set(handle, location);
            }
            else {
                console.log("Could not find handle for texture named: \'" + handle + "\'!");
            }
        }
    }
    // Bind the given Texture to the given texture unit
    bindTexToUnit(handleName, tex, unit) {
        this.use();
        var location = this.unifTexUnits.get(handleName);
        if (location !== undefined) {
            gl.activeTexture(gl.TEXTURE0 + unit);
            tex.bindTex();
            gl.uniform1i(location, unit);
        }
        else {
            console.log("Texture with handle name: \'" + handleName + "\' was not found");
        }
    }
    use() {
        if (activeProgram !== this.prog) {
            gl.useProgram(this.prog);
            activeProgram = this.prog;
        }
    }
    setModelMatrix(model) {
        this.use();
        if (this.unifModel !== -1) {
            gl.uniformMatrix4fv(this.unifModel, false, model);
        }
        if (this.unifModelInvTr !== -1) {
            let modelinvtr = mat4.create();
            mat4.transpose(modelinvtr, model);
            mat4.invert(modelinvtr, modelinvtr);
            gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
        }
    }
    setViewProjMatrix(vp) {
        this.use();
        if (this.unifViewProj !== -1) {
            gl.uniformMatrix4fv(this.unifViewProj, false, vp);
        }
        if (this.unifViewProjInv !== -1) {
            let viewProjInv = mat4.create();
            mat4.invert(viewProjInv, vp);
            gl.uniformMatrix4fv(this.unifViewProjInv, false, viewProjInv);
        }
    }
    setViewMatrix(vp) {
        this.use();
        if (this.unifView !== -1) {
            gl.uniformMatrix4fv(this.unifView, false, vp);
        }
        if (this.unifViewInv !== -1) {
            let viewinv = mat4.create();
            mat4.invert(viewinv, vp);
            gl.uniformMatrix4fv(this.unifViewInv, false, viewinv);
        }
    }
    setProjMatrix(vp) {
        this.use();
        if (this.unifProj !== -1) {
            gl.uniformMatrix4fv(this.unifProj, false, vp);
        }
    }
    setGeometryColor(color) {
        this.use();
        if (this.unifColor !== -1) {
            gl.uniform4fv(this.unifColor, color);
        }
    }
    setTime(t) {
        this.use();
        if (this.unifTime !== -1) {
            gl.uniform1f(this.unifTime, t);
        }
    }
    setDimension(d) {
        this.use();
        if (this.unifDimension !== -1) {
            gl.uniform2fv(this.unifDimension, d);
        }
    }
    setFar(f) {
        this.use();
        if (this.unifFar !== -1) {
            gl.uniform1f(this.unifFar, f);
        }
    }
    setEye(e) {
        this.use();
        if (this.unifEye !== -1) {
            gl.uniform4fv(this.unifEye, e);
        }
    }
    setCenter(center) {
        this.use();
        if (this.unifCenter !== -1) {
            gl.uniform3fv(this.unifCenter, center);
        }
    }
    setType(type) {
        this.use();
        if (this.unifType !== -1) {
            gl.uniform1i(this.unifType, type);
        }
    }
    setSSAOSamples(s) {
        this.use();
        if (this.unifSSAOSamples !== -1) {
            gl.uniform3fv(this.unifSSAOSamples, s, 0, 192);
        }
    }
    setShadowPMatrix(lightProjectionMatrix) {
        this.use();
        if (this.unifShadowPMatrix !== -1) {
            gl.uniformMatrix4fv(this.unifShadowPMatrix, false, lightProjectionMatrix);
        }
    }
    setShadowMVMatrix(lightViewMatrix) {
        this.use();
        if (this.unifShadowMVMatrix !== -1) {
            gl.uniformMatrix4fv(this.unifShadowMVMatrix, false, lightViewMatrix);
        }
    }
    setLightP(lightP) {
        this.use();
        if (this.unifLightP !== -1) {
            gl.uniformMatrix4fv(this.unifLightP, false, lightP);
        }
    }
    setLightV(lightV) {
        this.use();
        if (this.unifLightV !== -1) {
            gl.uniformMatrix4fv(this.unifLightV, false, lightV);
        }
    }
    draw(d) {
        this.use();
        if (this.attrPos != -1 && d.bindPos()) {
            gl.enableVertexAttribArray(this.attrPos);
            gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
        }
        if (this.attrNor != -1 && d.bindNor()) {
            gl.enableVertexAttribArray(this.attrNor);
            gl.vertexAttribPointer(this.attrNor, 4, gl.FLOAT, false, 0, 0);
        }
        if (this.attrCol != -1 && d.bindCol()) {
            gl.enableVertexAttribArray(this.attrCol);
            gl.vertexAttribPointer(this.attrCol, 4, gl.FLOAT, false, 0, 0);
        }
        if (this.attrUV != -1 && d.bindUV()) {
            gl.enableVertexAttribArray(this.attrUV);
            gl.vertexAttribPointer(this.attrUV, 2, gl.FLOAT, false, 0, 0);
        }
        d.bindIdx();
        gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);
        if (this.attrPos != -1)
            gl.disableVertexAttribArray(this.attrPos);
        if (this.attrNor != -1)
            gl.disableVertexAttribArray(this.attrNor);
        if (this.attrCol != -1)
            gl.disableVertexAttribArray(this.attrCol);
        if (this.attrUV != -1)
            gl.disableVertexAttribArray(this.attrUV);
    }
}
;
export default ShaderProgram;
//# sourceMappingURL=ShaderProgram.js.map