Shader "Unlit/LutShader"
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float3 _sunDir;
            float _sunLight;

            float _innerRadius, _outerRadius;

            float _baseDensity;
            float _densityFalloff;

            float3 _waveLens;
            float  _baseWaveLen;
           
            float _stepSize;
            int _maxSteps;

            #define PI          3.1415926535
            #define EPS         0.005

            float lengthSqr(float3 vec) { return dot(vec, vec); }
            float sqr(float t) { return t*t; }

            float isInsideOfAtmosphere(float3 pos)
            {
                return lengthSqr(pos) < sqr(_outerRadius); 
            }

            float sampleDensity(float3 pos)
            {
                float t = (length(pos) - _innerRadius) / (_outerRadius - _innerRadius);
                t = clamp(t, 0.0, 1.0);
                return (1.0-t)*exp(-t*_densityFalloff)*_baseDensity;
            }

            float3 trace(
                float3 rayOrigin, float3 rayDir,
                float3 coeffs)
            {
                float3 transmittance = 1.0;
                [loop]
                for (int i = 0; i < _maxSteps; i++)
                {
                    // hit planet 
                    if (lengthSqr(rayOrigin) < sqr(_innerRadius))
                        return 0.0;

                    // if lost almost all transmittance 
                    if (all(transmittance < EPS))
                        break;

                    // if not inside of atmosphere
                    if (!isInsideOfAtmosphere(rayOrigin))
                        break;

                    float density = sampleDensity(rayOrigin + 0.5 * _stepSize * _sunDir);
                    transmittance *= exp(-_stepSize * density * coeffs);
                    rayOrigin += _stepSize * _sunDir;
                }

                return transmittance * _sunLight;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //return fixed4(1.0, 0.0, 0.0, 1.0);

                float rad = lerp(_innerRadius, _outerRadius, i.uv.y);

                // float cosTheta, sinTheta;
                // sincos(i.uv.x * PI, sinTheta, cosTheta);

                // not uniform distribution of samples 
                // but i could not come up with smth smarter 
                // i think that if there is enough resolution problem should not 
                // be critical 
                float cosTheta = lerp(-1.0, 1.0, i.uv.x);
                float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

                float3 up = float3(0.0, 1.0, 0.0);
                float3 right = float3(1.0, 0.0, 0.0);

                float3 rnd = abs(dot(_sunDir, right)) < (1.0 - EPS) ? right : up;
                float3 perp = cross(_sunDir, normalize(cross(rnd, _sunDir)));

                float3 rayOrigin = (rad + EPS) * (cosTheta * _sunDir + sinTheta * perp);

                float3 coeffs = pow(_baseWaveLen / _waveLens, 4.0);
                
                return fixed4(trace(rayOrigin, _sunDir, coeffs), 1.0);
            }
            ENDCG
        }
    }
}
