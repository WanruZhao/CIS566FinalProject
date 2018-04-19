#version 300 es
precision highp float;

in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;
in vec2 fs_UV;

uniform sampler2D u_frame;
uniform float u_Time;
uniform vec2 u_Dimension;
uniform mat4 u_ViewProjInv;
uniform float u_Far;
uniform vec4 u_Eye;

out vec4 out_Col;

// Volumetric clouds
// reference: https://www.shadertoy.com/view/XslGRr

// vec3 sundir = normalize(vec3(0.0,2.0,-1.0));

// int maxStep = 100;

// float rand(float n){return fract(sin(n) * 43758.5453123);}

// float noise(vec3 x) {
//     vec3 p = floor(x);
//     vec3 f = fract(x);
//     f = f * f * (3.0 - 2.0 * f);

//     vec2 uv = (p.xy + vec2(370.0, 170.0) * p.z / 100.0 )+ f.xy;
//     vec2 rg = vec2(
//         texture(u_frame, (uv + 0.5) / 1000.0 ).xy
//     );

//     return 1.5 * mix(rg.x, rg.y, f.z) - 0.75;
// }

// float map5(vec3 p )
// {
// 	vec3 q = p - vec3(0.0,0.1,1.0)*u_Time / 10.0;
// 	float f;
//     f  = 0.50000*noise( q ); q = q*2.02;
//     f += 0.25000*noise( q ); q = q*2.03;
//     f += 0.12500*noise( q ); q = q*2.01;
//     f += 0.06250*noise( q ); q = q*2.02;
//     f += 0.03125*noise( q );
// 	return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
// }

// float map4(vec3 p)
// {
// 	vec3 q = p - vec3(0.0,0.1,1.0)*u_Time / 10.0;
// 	float f;
//     f  = 0.50000*noise( q ); q = q*2.02;
//     f += 0.25000*noise( q ); q = q*2.03;
//     f += 0.12500*noise( q ); q = q*2.01;
//     f += 0.06250*noise( q );
// 	return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
// }

// float map3(vec3 p)
// {
// 	vec3 q = p - vec3(0.0,0.1,1.0)*u_Time / 10.0;
// 	float f;
//     f  = 0.50000*noise( q ); q = q*2.02;
//     f += 0.25000*noise( q ); q = q*2.03;
//     f += 0.12500*noise( q );
// 	return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
// }

// float map2(vec3 p)
// {
// 	vec3 q = p - vec3(0.0,0.1,1.0)*u_Time / 10.0;
// 	float f;
//     f  = 0.50000*noise( q ); q = q*2.02;
//     f += 0.25000*noise( q );
// 	return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
// }

// vec4 integrate(vec4 sum,float dif,float den, vec3 bgcol, float t)
// {
//     // lighting
//     vec3 lin = vec3(0.65,0.7,0.75)*1.4 + vec3(1.0, 0.6, 0.3)*dif;        
//     vec4 col = vec4( mix( vec3(1.0,0.95,0.8), vec3(0.25,0.3,0.35), den), den);
//     col.xyz *= lin;
//     col.xyz = mix( col.xyz, bgcol, 1.0-exp(-0.003*t*t));

//     // front to back blending    
//     col.a *= 0.4;
//     col.rgb *= col.a;
//     return sum + col*(1.0-sum.a);
// }

// vec4 raymarch(vec3 ro, vec3 rd, vec3 bgcol, vec2 px)
// {
// 	vec4 sum = vec4(0.0);

// 	float t = 0.0;//0.05 * texture( u_frame,  vec2(int(px.x)&255, int(px.y)&255) ).x;

//     for(int i = 0; i < maxStep; i++) {
//         vec3 pos = ro + t * rd;
//         if(pos.y > 3.0 || pos.y < -3.0 || sum.a > 0.9) break;
//         float den = 2.0 * map5(pos);
//         if(den > 0.01) {
//             float dif = clamp((den - map5(pos + 0.3 * sundir)) / 0.6, 0.0, 1.0);
//             sum = integrate(sum, dif, den , bgcol, t);
//         }
//         t += max(0.005, 0.005 * t);
//         // t += 0.1;
//     }
//     for(int i = 0; i < maxStep; i++) {
//         vec3 pos = ro + t * rd;
//         if(pos.y > 3.0 || pos.y < -3.0 || sum.a > 0.9) break;
//         float den =  2.0 * map4(pos);
//         if(den > 0.01) {
//             float dif = clamp((den - map4(pos + 0.3 * sundir)) / 0.6, 0.0, 1.0);
//             sum = integrate(sum, dif, den , bgcol, t);
//         }
//         t += max(0.005, 0.005 * t);
//         // t += 0.1;
//     }
//     for(int i = 0; i < maxStep; i++) {
//         vec3 pos = ro + t * rd;
//         if(pos.y > 3.0 || pos.y < -3.0 || sum.a > 0.9) break;
//         float den = 2.0 * map3(pos);
//         if(den > 0.01) {
//             float dif = clamp((den - map3(pos + 0.3 * sundir)) / 0.6, 0.0, 1.0);
//             sum = integrate(sum, dif, den , bgcol, t);
//         }
//         t += max(0.005, 0.005 * t);
//         // t += 0.1;
//     }
//     for(int i = 0; i < maxStep; i++) {
//         vec3 pos = ro + t * rd;
//         if(pos.y > 3.0 || pos.y < -3.0 || sum.a > 0.9) break;
//         float den = 2.0 * map2(pos);
//         if(den > 0.01) {
//             float dif = clamp((den - map2(pos + 0.3 * sundir)) / 0.6, 0.0, 1.0);
//             sum = integrate(sum, dif, den , bgcol, t);
//         }
//         t += max(0.005, 0.005 * t);
//     }

//     return clamp( sum, 0.0, 1.0 );
// }

// mat3 setCamera(vec3 ro, vec3 ta, float cr )
// {
// 	vec3 cw = normalize(ta-ro);
// 	vec3 cp = vec3(sin(cr), cos(cr),0.0);
// 	vec3 cu = normalize( cross(cw,cp) );
// 	vec3 cv = normalize( cross(cu,cw) );
//     return mat3( cu, cv, cw );
// }

// vec4 render(vec3 ro, vec3 rd, vec2 px )
// {
//     // background sky     
// 	float sun = clamp( dot(sundir,rd), 0.0, 1.0 );
// 	vec3 col = vec3(0.0);//vec3(0.6,0.71,0.75) - rd.y*0.2*vec3(1.0,0.5,1.0) + 0.15*0.5;
// 	// col += 0.2*vec3(1.0,.6,0.1)*pow( sun, 8.0 );

//     // clouds    
//     vec4 res = raymarch( ro, rd, col, px );
//     col = col*(1.0-res.w) + res.xyz;
    
//     return vec4( col, 1.0 );
// }

// void main() {
//     vec2 p = (-u_Dimension + 2.0*gl_FragCoord.xy)/ u_Dimension.y;
    
//     // // camera
//     vec3 ro = 4.0*normalize(vec3(sin(3.0), 0.4, cos(3.0)));
// 	vec3 ta = vec3(0.0, 0.0, 0.0);
//     mat3 ca = setCamera( ro, ta, 0.0 );

//     // // ray
//     vec3 rd = normalize( vec3(p.xy, 1.0));
//     // vec4 eye = u_Eye;

// 	// vec2 coord = gl_FragCoord.xy;
// 	// vec3 dir = rayDirection(coord, u_Dimension, eye);
    
//     out_Col = render( ro, rd, vec2(0.0) );
// }





//Cloud Ten by nimitz (twitter: @stormoid)

mat2 mm2(float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}

float noise(float t){return texture(u_frame,vec2(t,.0)/u_Dimension.xy).x;}
float moy = 0.0;

float noise(vec3 x) //3d noise from iq
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = texture( u_frame, (uv+ 0.5)/256.0, 0.0 ).yx;
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

float path(float x){ return sin(x*0.01-3.1415)*28.+6.5; }
float map(vec3 p){
    return p.x*0.07 + (fbm(p*0.3)-0.1) + sin(p.x*0.24 + sin(p.z*.01)*7.)*0.22+ 0.2 + sin(p.z*0.08)*0.05;
}

float march(vec3 ro, vec3 rd)
{
    float precis = .3;
    float h= 1.;
    float d = 0.;
    for( int i=0; i<17; i++ )
    {
        if( abs(h)<precis || d>70. ) break;
        d += h;
        vec3 pos = ro+rd*d;
        pos.y += .5;
	    float res = map(pos)*7.;
        h = res;
    }
	return d;
}

vec3 lgt = vec3(0);
float mapV( vec3 p ){ return clamp(-map(p), 0., 1.);}
vec4 marchV(vec3 ro, vec3 rd, float t, vec3 bgc)
{
	vec4 rz = vec4( 0.0 );
	
	for( int i=0; i<50; i++ )
	{
		if(rz.a > 0.99 || t > 100.) break;
		
		vec3 pos = ro + t*rd;
        float den = mapV(pos);
        
        vec4 col = vec4(mix( vec3(.8,.75,.85), vec3(.0), den ),den);
        col.xyz *= mix(bgc*bgc*2.5,  mix(vec3(0.1,0.2,0.55),vec3(.8,.85,.9),moy*0.4), clamp( -(den*40.+0.)*pos.y*.03-moy*0.5, 0., 1. ) );
        col.rgb += clamp((1.-den*6.) + pos.y*0.13 +.55, 0., 1.)*0.35*mix(bgc,vec3(1),0.7); //Fringes
        col += clamp(den*pos.x*.15, -.02, .0); //Depth occlusion
        col *= smoothstep(0.2+moy*0.05,.0,mapV(pos+1.*lgt))*.85+0.15; //Shadows
        
		col.a *= .9;
		col.rgb *= col.a;
		rz = rz + col*(1.0 - rz.a);

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
	
    return vec3(0.0);//vec3(clamp(rz,0.,1.));
}

mat3 rot_x(float a){float sa = sin(a); float ca = cos(a); return mat3(1.,.0,.0,    .0,ca,sa,   .0,-sa,ca);}
mat3 rot_y(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,.0,sa,    .0,1.,.0,   -sa,.0,ca);}
mat3 rot_z(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,sa,.0,    -sa,ca,.0,  .0,.0,1.);}

void main()
{	
    vec2 q = gl_FragCoord.xy / u_Dimension.xy;
    vec2 p = q - 0.5;
	float asp =u_Dimension.x/u_Dimension.y;
    p.x *= asp;
	vec2 mo = vec2(0.0);//iMouse.xy / u_Dimension.xy;
	moy = mo.y;
    mo.y = 0.0;
    float st = 0.0;//sin(u_Time*0.3-1.3)*0.2;
    vec3 ro = vec3(-2.+sin(u_Time*.3-1.)*2.,0.0, u_Time/3.);
    ro.x = path(ro.z);
    vec3 ta = ro + vec3(0,0,1);
    vec3 fw = normalize(ta - ro);
    vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), fw ));
    vec3 vv = normalize(cross(fw,uu));
    const float zoom = 1.;
    vec3 rd = normalize( p.x*uu + p.y*vv + -zoom*fw );
    
    float rox = 0.0;//sin(u_Time*0.2)*0.8+2.9;
    //rox += smoothstep(0.6,1.2,sin(time*0.25))*3.5;
   	float roy = 0.0;//sin(time*0.5)*0.2;
    mat3 rotation = rot_x(-roy)*rot_y(-rox+st*1.5)*rot_z(st);
	mat3 inv_rotation = rot_z(-st)*rot_y(rox-st*1.5)*rot_x(roy);
    rd *= rotation;
    rd.y -= dot(p,p)*0.06;
    rd = normalize(rd);
    
    vec3 col = vec3(0.);
    lgt = normalize(vec3(-0.3,0.1,1.));  
    float rdl = clamp(dot(rd, lgt),0.,1.);
  
    vec3 hor = mix( vec3(.9,.6,.7)*0.35, vec3(.5,0.05,0.05), rdl );
    hor = mix(hor, vec3(.5,.8,1),0.0);
    col += mix( vec3(.2,.2,.6), hor, exp2(-(1.+ 3.*(1.-rdl))*max(abs(rd.y),0.)) )*.6;
    col += .8*vec3(1.,.9,.9)*exp2(rdl*650.-650.);
    col += .3*vec3(1.,1.,0.1)*exp2(rdl*100.-100.);
    col += .5*vec3(1.,.7,0.)*exp2(rdl*50.-50.);
    col += .4*vec3(1.,0.,0.05)*exp2(rdl*10.-10.);  
    vec3 bgc = col;
    
    float rz = march(ro,rd);
    
    if (rz < 50.)
    {   
        vec4 res = marchV(ro, rd, rz-5., bgc);
    	col = col*(1.0-res.w) + res.xyz;
    }
    
    vec3 projected_flare = (-lgt*inv_rotation);
    col += 1.4*vec3(0.7,0.7,0.4)*max(flare(p,-projected_flare.xy/projected_flare.z*zoom)*projected_flare.z,0.);
    
    float g = 0.0;//smoothstep(0.03,.97,mo.x);
    col = mix(mix(col,col.brg*vec3(1,0.75,1),clamp(g*2.,0.0,1.0)), col.bgr, clamp((g-0.5)*2.,0.0,1.));
    
	col = clamp(col, 0., 1.);
    col = col*0.5 + 0.5*col*col*(3.0-2.0*col); //saturation
    col = pow(col, vec3(0.416667))*1.055 - 0.055; //sRGB
	col *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.12 ); //Vign

	out_Col = vec4( col, 1.0 );
}