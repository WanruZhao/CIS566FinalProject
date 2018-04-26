#version 300 es
precision highp float;

in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;
in vec2 fs_UV;

uniform sampler2D u_frame; // noise
uniform sampler2D u_frame2; // fish
uniform sampler2D u_frame3; // depth

uniform float u_Time;
uniform vec2 u_Dimension;
uniform mat4 u_ViewProjInv;
uniform float u_Far;
uniform vec4 u_Eye;

out vec4 out_Col;




//Cloud Ten by nimitz (twitter: @stormoid)


const float zoom = 1.;
vec3 lgt = vec3(0);
float moy = 3.0;


mat2 mm2(float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}

float noise(float t){return texture(u_frame,vec2(t,.0)/u_Dimension.xy).x;}

float noise(vec3 x) //3d noise from iq
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = texture( u_frame,  fract((uv+ 0.5)/256.0)).yx;
	return mix( rg.x, rg.y, f.z );
}

float fbm(vec3 x)
{
    float rz = 0.;
    float a = .35;
    for (int i = 0; i<2; i++)
    {
        rz += noise(x)*a;
        a*=.35;
        x*= 4.;
    }
    return rz;
}

float path(float x){ 
    return sin(x*0.01-3.1415)*28.+6.5;
}

float map(vec3 p){
    return p.x*0.07 + (fbm(p*0.3)-0.1) + sin(p.x*1.5 + sin(p.z*.01)*7.)*0.22+ 0.4 + sin(p.z*0.08)*0.05;
}

float march(vec3 ro, vec3 rd)
{
    float precis = .1;
    float h= 1.;
    float d = 0.;
    for( int i=0; i<17; i++ )
    {
        if( abs(h)<precis || d> 70. ) break;
        d += h;
        vec3 pos = ro+rd*d;
        pos.y += .5;
	    float res = map(pos)*7.;
        h = res;
    }
	return d;
}


float mapV( vec3 p ){ return clamp(-map(p), 0., 1.);}

vec4 marchV(vec3 ro, vec3 rd, float t, vec3 bgc)
{
	vec4 rz = vec4( 0.0 );

    float depth = texture(u_frame3, fs_UV).x;

	for( int i=0; i<200; i++ )
	{

        if(rz.a > 0.99 || t > 50.) break;

        vec3 pos = ro + t*rd;

        float den = mapV(pos);
        
        vec4 col = vec4(mix( vec3(.8,.75,.85), vec3(.0), den ),den);
        col.xyz *= mix(bgc*bgc*2.5,  mix(vec3(0.1,0.2,0.55),vec3(.8,.85,.9),moy*0.4), clamp( -(den*40.+0.)*pos.y*.03-moy*0.5, 0., 1. ) );
        col.rgb += clamp((1.-den*6.) + pos.y*0.13 +.55, 0., 1.)*0.35*mix(bgc,vec3(1),0.7); //Fringes
        col += clamp(den*pos.x*.15, -.02, .0); //Depth occlusion
        col *= smoothstep(0.1+0.0*0.05,.0,mapV(pos+1.*lgt))*.85+0.15; //Shadows

        
        
		col.a *= .9;
		col.rgb *= col.a;
		rz = rz + col*(1.0 - rz.a);

        if(abs(pos.z - depth * 99.0)< 2.0) {
            break;
        }

        t += max(.4,(2.-den*30.)*t*0.011);
	}

	return clamp(rz, 0., 1.);
}

float pent(vec2 p){    
    vec2 q = abs(p);
    return max(max(q.x*1.176-p.y*0.385, q.x*0.727+p.y), -p.y*1.237)*1.;
}

vec3 flare(vec2 p, vec2 pos) //Inspired by mu6k's lens flare (https://www.shadertoy.com/view/4sX3Rs)
{
	vec2 q = p-pos;
    vec2 pds = p*(length(p))*0.75;
	float a = atan(q.x,q.y);
	
    float rz = .55*(pow(abs(fract(a*.8+.12)-0.5),3.)*(noise(a*15.)*0.9+.1)*exp2((-dot(q,q)*4.))); //Spokes
	
    rz += max(1.0/(1.0+32.0*pent(pds+0.8*pos)),.0)*00.2; //Projected ghost (main lens)
    vec2 p2 = mix(p,pds,-.5); //Reverse distort
	rz += max(0.01-pow(pent(p2 + 0.4*pos),2.2),.0)*3.0;
	rz += max(0.01-pow(pent(p2 + 0.2*pos),5.5),.0)*3.0;	
	rz += max(0.01-pow(pent(p2 - 0.1*pos),1.6),.0)*4.0;
    rz += max(0.01-pow(pent(-(p2 + 1.*pos)),2.5),.0)*5.0;
    rz += max(0.01-pow(pent(-(p2 - .5*pos)),2.),.0)*4.0;
    rz += max(0.01-pow(pent(-(p2 + .7*pos)),5.),.0)*3.0;
	
    return vec3(clamp(rz,0.,1.));
}

mat3 rot_x(float a){float sa = sin(a); float ca = cos(a); return mat3(1.,.0,.0,    .0,ca,sa,   .0,-sa,ca);}
mat3 rot_y(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,.0,sa,    .0,1.,.0,   -sa,.0,ca);}
mat3 rot_z(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,sa,.0,    -sa,ca,.0,  .0,.0,1.);}


vec3 calculateDirection(vec3 ta, vec3 ro, vec2 p) {
    vec3 fw = normalize(ta - ro);
    vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), fw ));
    vec3 vv = normalize(cross(fw,uu));
    vec3 rd = normalize( p.x*uu + p.y*vv + -zoom*fw );
    return rd;
}

vec3 waterB(vec3 direction) {
    vec3 col = vec3(0.0);
    lgt = normalize(vec3(0.6,0.1,1.));  
    float rdl = clamp(dot(direction, lgt),0.,1.);

    vec3 hor = mix( vec3(.9,.6,.7)*0.35, vec3(.5,0.5,0.5), rdl );
    hor = mix(hor, vec3(.8,.5,1),0.5);
    col += mix( vec3(.2,.2,.8), hor, exp2(-(1.+ 3.*(1.-rdl))*max(abs(direction.x),0.)) )*.6;//1.2 * exp2(-(0.8+ 0.8*(1.-rdl * sin(u_Time / 2.0)))*max(abs(direction.x + texture(u_frame, (direction.xy + vec2(u_Time / 30.0, u_Time / 30.0)) / (60.0 * u_Dimension / u_Dimension.y)).y),0.)) )*.5;
    col += .8*vec3(1.,.9,.5)*exp2(rdl*650.-650.);
    col += .3*vec3(1.,1.,0.1)*exp2(rdl*100.-100.);
    col += .5*vec3(1.,.7,0.)*exp2(rdl*50.-50.);
    col += .4*vec3(1.,0.,0.05)*exp2(rdl*10.-10.);  
    return col;
}

vec3 skyB(vec3 direction) {
    vec3 col = vec3(0.0);
    lgt = normalize(vec3(1.0,1.0,0.8));  
    float rdl = clamp(dot(direction, lgt),0.,1.);

    vec3 hor = mix( vec3(.9,.9,.5)*1.0, vec3(1.0,0.8,0.6), rdl );
    hor = mix(hor, vec3(.8,.8, 0.6),0.4);
    // col += mix( vec3(.8,.8,.0), hor, 1.2 * exp2(-(1.0+ 0.8*(1.-rdl))*max(abs(direction.x - 0.5),0.)) )*0.8;
    // col += .8*vec3(1.,.9,.5)*exp2(rdl*650.-650.);
    // col += .3*vec3(1.,1.,0.1)*exp2(rdl*100.-100.);
    // col += .5*vec3(1.,.7,0.)*exp2(rdl*50.-50.);
    // col += .4*vec3(1.,0.,0.05)*exp2(rdl*10.-10.);  
    col = hor;
    return col;
}



void main()
{	


    // split the screen 
    vec2 q = gl_FragCoord.xy / u_Dimension.xy;
    vec2 p;
    float depth = texture(u_frame3, fs_UV).w;
    vec3 tex = texture(u_frame2, fs_UV).xyz;

    // draw left part: sky
    if(q.x < 0.5) {
        
                // translate pixel from leftmost to the middle
        p = vec2(1.0 - q.x - 0.75, q.y);

        // calibrate the scale
        float asp =u_Dimension.x/u_Dimension.y;
        p.x *= asp;

        // set ray marching camera parameters    
        float st = 0.0;// sin(u_Time*0.3-1.3)*0.2;
        vec3 origin = vec3(0.0, -0.1, 0.0);
        //ro.x = path(ro.x);
        vec3 target = origin + vec3(0.0, 0.1,0.1);
        vec3 direction = calculateDirection(target, origin, p);
        
        
        // camera animation
        #ifdef CAMERA_MOVE
        float rox = 0.0;
        //rox += smoothstep(0.6,1.2,sin(time*0.25))*3.5;
        float roy = 0.0;//sin(u_Time*0.02)*0.8+2.9;
        mat3 rotation = rot_x(-roy)*rot_y(-rox+st*1.5)*rot_z(st);
        mat3 inv_rotation = rot_z(-st)*rot_y(rox-st*1.5)*rot_x(roy);
        direction *= rotation;
        direction.y -= dot(p,p)*0.06;
        direction = normalize(direction);
        #endif
        

        // calculate background color
        vec3 col = skyB(direction);
        vec3 bgc = col;


        // find out the ray density
        float rz = march(origin,direction);

        // if cloud if behind the fish, render fish
        if(rz >= depth * 99.9 && depth < 0.99999) {
            col = tex;
        } 
        
        else {
            // set the col to fish color
            if(depth < 0.9999){
                col = tex; 
            }
            
            // if depth of cloud is within threshold, ray marching noise function to get the volumetric cloud
            if (rz < 100.)
            {   
                vec4 res = marchV(origin, direction, rz-5., bgc);
                // res.xyz += res.xyz * 0.5;
                col = col*(1.0-res.w ) + res.xyz;
            }
        }

        
        //============================post effects===========================================
        vec3 projected_flare = (lgt);//*inv_rotation);
        // col += 1.4*vec3(0.7,0.7,0.4)*max(flare(p,-projected_flare.xy/projected_flare.z*zoom)*projected_flare.z,0.);
        
        float g = smoothstep(0.03,.97,0.6);
        col = mix(mix(col,col.rgb*vec3(0.8,0.8,0.4),clamp(g*2.,0.0,1.0)), col.rgb, clamp((g-0.5)*2.,0.0,1.));
        
        col = clamp(col, 0., 1.);
        col = col*0.5 + 0.5*col*col*(2.0-1.0*col); //saturation
        col = pow(col, vec3(0.416667))*1.055 - 0.055; //sRGB
        col *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.12 ); //Vign

        out_Col = vec4( col, 1.0 );

    }

    // draw right part: water
    else {
        
        // translate pixel from leftmost to the middle
        p = q - vec2(0.75, 0.0);

        // calibrate the scale
        float asp =u_Dimension.x/u_Dimension.y;
        p.x *= asp;

        // set ray marching camera parameters    
        float st = 0.0;// sin(u_Time*0.3-1.3)*0.2;
        vec3 origin = vec3(0.0, 0.1, 0.0);
        //ro.x = path(ro.x);
        vec3 target = origin + vec3(0.0, 0.0,0.1);
        vec3 direction = calculateDirection(target, origin, p);
        
        
        // camera animation
        #ifdef CAMERA_MOVE
        float rox = 0.0;
        //rox += smoothstep(0.6,1.2,sin(time*0.25))*3.5;
        float roy = 0.0;//sin(u_Time*0.02)*0.8+2.9;
        mat3 rotation = rot_x(-roy)*rot_y(-rox+st*1.5)*rot_z(st);
        mat3 inv_rotation = rot_z(-st)*rot_y(rox-st*1.5)*rot_x(roy);
        direction *= rotation;
        direction.y -= dot(p,p)*0.06;
        direction = normalize(direction);
        #endif
        

        // calculate background color
        vec3 col = waterB(direction);
        vec3 bgc = col;


        // find out the ray density
        float rz = march(origin,direction);

        // if cloud if behind the fish, render fish
        if(rz >= depth * 99.9 && depth < 0.99999) {
            col = tex;
        } 
        
        else {
            // set the col to fish color
            if(depth < 0.9999){
                col = tex; 
            }
            
            // if depth of cloud is within threshold, ray marching noise function to get the volumetric cloud
            if (rz < 100.)
            {   
                vec4 res = marchV(origin, direction, rz-5., bgc);
                // res.xyz += res.xyz * 0.5;
                col = col*(1.0-res.w ) + res.xyz;
            }
        }

        
        //============================post effects===========================================
        vec3 projected_flare = (-lgt);//*inv_rotation);
        // col += 1.4*vec3(0.7,0.7,0.4)*max(flare(p,-projected_flare.xy/projected_flare.z*zoom)*projected_flare.z,0.);
        
        float g = smoothstep(0.03,.97,0.51);
        col = mix(mix(col,col.grb*vec3(0.0,0.75,0.7),clamp(g*2.,0.0,1.0)), col.brg, clamp((g-0.5)*2.,0.0,1.));
        
        col = clamp(col, 0., 1.);
        col = col*0.5 + 0.5*col*col*(4.0-3.0*col); //saturation
        col = pow(col, vec3(0.416667))*1.055 - 0.055; //sRGB
        col *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.12 ); //Vign

        out_Col = vec4( col, 1.0 );
    }

    // out_Col = vec4(tex, 1.0);

	
}