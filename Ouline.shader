Shader "Unlit/Ouline"
{
    Properties
    {
        _MainTex("MainTex",2D)="white"{}
        _MainColor("Main Color",Color)=(1,1,1)
        _ShadowColor("Shadow Color",Color)=(0.7,0.7,0.8)
        _ShadowRange("Shadow Range",Range(0,1))=0.5
        _ShadowSmooth("Shadow Smooth",Range(0,1))=0.2

        _RimColor("RimColor",Color)=(1,1,1,1)
        _RimMin("RimMin",Float)=0
        _RimMax("RimMax",Float)=1
        _RimSmooth("RimSmooth",Float)=1

        [Space(10)]
        _OutlineWidth("Outline Width",Range(0.01,1))=0.24
        _OutlineColor("Outline Color",Color)=(0.5,0.5,0.5,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            Cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half3 _MainColor;
            half3 _ShadowColor;
            half _ShadowRange;
            half _ShadowSmooth;
            half4 _RimColor;
            float _RimMin;
            float _RimMax;
            float _RimSmooth;

            struct a2v
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float2 uv:TEXCOORD0;
            };
            struct v2f
            {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0;
                float3 worldNormal:TEXCOORD1;
                float3 worldPos:TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f,o);
                o.uv=TRANSFORM_TEX(v.uv,_MainTex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.pos=UnityObjectToClipPos(v.vertex);
                return o;
            }
            half4 frag(v2f i):SV_TARGET
            {
                half4 col=1;
                half4 mainTex=tex2D(_MainTex,i.uv);
                half3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                half3 worldNormal=normalize(i.worldNormal);
                half3 worldLightDir=normalize(_WorldSpaceLightPos0.xyz);
                half halfLambert=dot(worldNormal,worldLightDir)*0.5+0.5;
                //half3 diffuse=halfLambert>_ShadowRange?_MainColor:_ShadowColor;
                half ramp=smoothstep(0,_ShadowSmooth,halfLambert-_ShadowRange);
                half3 diffuse=lerp(_ShadowColor,_MainColor,ramp);
                diffuse*=mainTex;

                half f=1.0-saturate(dot(viewDir,worldNormal));
                half rim=smoothstep(_RimMin,_RimMax,f);
                rim=smoothstep(0,_RimSmooth,rim);
                half3 rimColor=rim*_RimColor.rgb*_RimColor.a;

                col.rgb=_LightColor0.rgb*(diffuse+rimColor);
                return col;
            }
            ENDCG
        }

        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            half _OutlineWidth;
            half4 _OutlineColor;

            struct a2v
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float2 uv:TEXCOORD0;
                float4 vertColor:COLOR;
                float4 tangent:TANGENT;
            };
            struct v2f
            {
                float4 pos:SV_POSITION;
            };
            v2f vert(a2v v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f,o);
                float4 pos=UnityObjectToClipPos(v.vertex);
                float3 viewNormal=mul((float3x3)UNITY_MATRIX_IT_MV,v.normal.xyz);
                //讲法线变换到NDC空间
                float3 ndcNormal=normalize(TransformViewToProjection(viewNormal.xyz))*pos.w;
                //将近裁面右上角位置的顶点变换到观察空间
                float4 nearUpperRight=mul(unity_CameraInvProjection,float4(1,1,UNITY_NEAR_CLIP_VALUE,_ProjectionParams.y));
                //求得屏幕宽高比
                float aspect=abs(nearUpperRight.y/nearUpperRight.x);
                //顶点延法线方向外扩
                ndcNormal.x*=aspect;
                pos.xy+=0.01*_OutlineWidth*ndcNormal.xy;
                o.pos=pos;
                return o;
            }
            half4 frag(v2f i):SV_TARGET
            {
                return _OutlineColor;
            }
            ENDCG
        }
    }
}
