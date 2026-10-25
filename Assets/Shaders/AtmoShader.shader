Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 dir : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float4 _MainTex_ST;

            // CUSTOM PARAMS
            float4x4  _invMatrix;
            sampler2D _lutTexture;
           
            float3 _sunDir;
            float  _sunLight;

            float3 _planetPos;
            float _innerRadius, _outerRadius;
           
            float _baseDensity;
            float _densityFalloff;

            float3 _waveLens;
            float  _baseWaveLen;
           
            float _stepSize;
            int   _maxSteps;

            #define PI          3.1415926535
            #define EPS         0.005

            float lengthSqr(float3 vec) { return dot(vec, vec); }
            float sqr(float t) { return t*t; }

            // distance to first point of ray-sphere intersection 
            float getEntryDist(float3 rayOrigin, float3 rayDir, float3 spherePos, float sphereRad)
            {
                // if inside of sphere 
                float3 delta = rayOrigin - spherePos;
                if (lengthSqr(delta) < sqr(sphereRad))
                    return 0.0;

                float a = dot(rayDir, rayDir);
                float b = 2.0 * dot(delta, rayDir);
                if (b > 0.0) // if sphere behind ray
                    return -1.0;

                float c = dot(delta, delta) - sphereRad * sphereRad;
                float d = b*b-4.0*a*c;
                if (d < 0.0)
                    return -1.0;

                d = sqrt(d);

                float3 t1 = (-b - d) / (2.0*a); 
                float3 t2 = (-b + d) / (2.0*a); 
                
                float t = min(t1, t2) + EPS;
                return t;
            }

            float isInsideOfAtmosphere(float3 pos)
            {
                return lengthSqr(pos - _planetPos) < sqr(_outerRadius); 
            }

            // delta is vector from sphere center to point 
            float sampleDensity(float3 pos)
            {
                float t = (length(pos - _planetPos) - _innerRadius) / (_outerRadius - _innerRadius);
                t = clamp(t, 0.0, 1.0);
                return (1.0-t)*exp(-t*_densityFalloff)*_baseDensity;
            }

            // depth from z-buffer
            float getDepth(float2 uv, float3 dir)
            {
                float eyeDepth = LinearEyeDepth(tex2D(_CameraDepthTexture, uv).r);
                float3 forward = unity_CameraToWorld._m02_m12_m22; // y vector forward
                return eyeDepth / dot(dir, forward);
            }

            float getPhase(float3 a, float3 b)
            {
                float cosSqr = dot(a, b) * dot(a, b);
                return 3.0 / (16.0 * PI) * (1.0 + cosSqr); 
            }

            float3 trace(float3 rayOrigin, float3 rayDir)
            {
                float3 delta = rayOrigin - _planetPos;
                float  deltaLen = length(delta);
                float3 deltaNorm = delta / deltaLen;

                float cos01 = 0.5 * dot(deltaNorm, _sunDir) + 0.5;
                float rad01 = (deltaLen - _innerRadius) / (_outerRadius - _innerRadius);

                return tex2D(_lutTexture, float2(cos01, rad01));
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.dir = mul(_invMatrix, float4(o.uv, 1.0, 1.0));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.dir);
                float maxDepth = getDepth(i.uv, rayDir);
                float4 color = tex2D(_MainTex, i.uv);

                float t = getEntryDist(rayOrigin, rayDir, _planetPos, _outerRadius);
                if (t < 0.0)
                    return color;

                rayOrigin += rayDir * t;

                float3 coeffs = pow(_baseWaveLen / _waveLens, 4.0);
                float3 transmittance = 1.0;
                float3 accum = 0.0;

                float3 halfStep = 0.5 * _stepSize * rayDir;

                [loop]
                for (int i = 0; i < _maxSteps; i++)
                {
                    // depth buffer value is less 
                    if (t >= maxDepth)
                        break;

                    // if lost almost all transmittance 
                    if (all(transmittance < EPS))
                        break;

                    // if not inside of atmosphere
                    if (!isInsideOfAtmosphere(rayOrigin))
                        break;

                    float density = sampleDensity(rayOrigin + halfStep);
                    transmittance *= exp(-_stepSize * density * coeffs);
                    accum += density * transmittance * trace(rayOrigin, rayDir);

                    rayOrigin += _stepSize * rayDir;
                    t += _stepSize;
                }

                float phase = getPhase(-rayDir, _sunDir);
                accum *= _stepSize * coeffs * phase;

                return float4(accum + transmittance * color, 1.0);
            }
            ENDCG
        }
    }
}
