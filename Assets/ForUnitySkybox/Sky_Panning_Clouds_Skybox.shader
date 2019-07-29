Shader "Skybox/Sky_Panning_Clouds2_Skybox"
{
    Properties
    {
        _OverallColor ("_OverallColor", Color) = (1,1,1,1)
        _MainTex ("MainTex", 2D) = "white" {}
        _SunRadius ("Sun Radius", Float) = 0.0003
        _SunBrightness ("Sun Brightness", Float) = 50
        _HorizonColor ("Horizon Color", Color) = (0.940601,1,1,1)
        _HorizonFalloff ("Horizon Falloff", Float) = 3
        _ZenithColor ("Zenith Color", Color) = (0.085177,0.153746,0.35,1)
        _CloudTex ("CloudTex", 2D) = "white" {}
        _CloudSpeed ("Cloud Speed", Float) = 0.1
        _NoisePower1 ("NoisePower1", Float) = 1
        _NoisePower2 ("NoisePower2", Float) = 4
        _CloudColor ("Cloud Color", Color) = (0.71685,0.782221,0.885,0)
        _CloudOpacity ("Cloud Opacity", Float) = 1
        _StarTex ("StarTex", 2D) = "white" {}
        _StarBrightness ("Star Brightness", Float) = 0.1
        _StarHeight ("Star Height", Float) = 1
    }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma enable_d3d11_debug_symbols
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            //#include "../../BnSFog/BnSFogCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 uv : TEXCOORD0;
                float4 worldPosPack : TEXCOORD1;
                UNITY_FOG_COORDS(2)
                //BNS_FOG_COORDS(2)
            };

            fixed4 _OverallColor;
            sampler2D _MainTex;
            float _SunRadius;
            float _SunBrightness;
            float _StarHeight;
            fixed4 _HorizonColor;
            float _HorizonFalloff;
            fixed4 _ZenithColor;
            sampler2D _CloudTex;
            float4 _CloudTex_ST;
            float _CloudSpeed;
            float _NoisePower1;
            float _NoisePower2;
            fixed4 _CloudColor;
            float _CloudOpacity;
            sampler2D _StarTex;
            float4 _StarTex_ST;
            float _StarBrightness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.vertex.xyz;

                float cloudFactor = (1 - saturate(-10*v.vertex.y)) * _CloudOpacity;
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldPosPack = float4(worldPos, cloudFactor);

                UNITY_TRANSFER_FOG(o,o.vertex);
                //BNS_TRANSFER_FOG(o,worldPos);
                return o;
            }

            float SphereMask(float a, float b, float r)
            {
                float l = abs(a - b);
                float nl = l / r;
                return saturate(1 - nl);
            }

            inline float2 ToRadialCoords(float3 pos)
            {
                float2 uv;
                uv.x = 0.5 - atan2(pos.x, pos.z) / UNITY_TWO_PI;
                uv.y = asin(abs(pos.y)) / UNITY_HALF_PI;
                uv.y += 0.001;     // fix horizon seam
                return uv;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = ToRadialCoords(i.uv);
                float cloudFactor = i.worldPosPack.w;
                float3 worldPos = i.worldPosPack.xyz;
                float3 cameraVector = normalize(_WorldSpaceCameraPos - worldPos);

                //HorizonDistribution
                float hdOut1 = saturate(-cameraVector.y);
                float hdOut2 = saturate(pow(1 - hdOut1, _HorizonFalloff));

                //CloudTextures
                float speedFactor = _Time.x * _CloudSpeed;
                fixed cloud1 = tex2D(_CloudTex, float2(speedFactor * 0.001, 0) + uv).r;
                fixed main = tex2D(_MainTex, float2(speedFactor * 0.0002, 0) + uv).r;
                fixed cloud2 = tex2D(_CloudTex, uv * _CloudTex_ST.xy + 0.5).r;
                float ctTmp = lerp(main, cloud1, hdOut1);
                float ctOut1 = lerp(0, ctTmp, cloudFactor);
                float ctOut2 = lerp(_NoisePower1, _NoisePower2, cloud2);

                //SunVector
                float3 lightDir = -_WorldSpaceLightPos0.xyz;
                float svOut = dot(cameraVector, normalize(lightDir));

                //Sun
                half3 sunColor = _LightColor0;
                float3 sunOut = SphereMask(svOut, 1, _SunRadius) * sunColor * _SunBrightness;

                //SkyColors
                fixed3 star = tex2D(_StarTex, uv * _StarTex_ST.xy);
                float3 scTmp = _ZenithColor + star * _StarBrightness * _StarHeight;
                float3 scOut = lerp(scTmp, _HorizonColor, hdOut2);

                //RimLight
                float rlTmp1 = pow(ctOut1, ctOut2);
                float3 rlOut1 = _CloudColor * rlTmp1;
                float rlOut2 = rlTmp1 * rlTmp1;
                float rlTmp2 = SphereMask(svOut, 1, 1.3);
                float rlTmp3 = saturate(pow(rlTmp2, 10));
                float3 rlOut3 = rlTmp3 * sunColor * rlOut2 * 0.4;

                float3 tmp1 = rlOut1 + rlOut3;
                float3 tmp2 = sunOut + scOut;

                //GlobalParameters
                float3 gpOut = lerp(tmp2, tmp1, saturate(rlOut2)) * _OverallColor;

                fixed4 col = fixed4(gpOut * 1.5, 1);
                UNITY_APPLY_FOG(i.fogCoord, col);
                //BNS_APPLY_FOG(i, col, worldPos);
                return col;
            }
            ENDCG
        }
    }
}
