Shader "MyShader/Chapter7/RampTexture" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_RampTex ("Ramp Tex", 2D) = "white" {}
		_Specular("Specular",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8.0,256))=20
	}
	SubShader {
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			fixed4 _Color;
			sampler2D _RampTex;
			float4 _RampTex_ST;
			fixed4 _Specular;
			float _Gloss;

			struct a2v
			{
				float4 vertex:POSITION;
				float3 normal:NORMAL;
				float4 texcoord:TEXCOORD0;
			};

			struct v2f
			{
				float4 pos:SV_POSITION;
				float3 worldNormal:TEXCOORD0;//用于计算光照
				float3 worldPos:TEXCOORD1;//用于得到视角方向和光照方向
				float2 uv:TEXCOORD2;//用于纹理采样
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.texcoord,_RampTex);
				return o;
			}

			fixed4 frag(v2f i):SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				//自然光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				//计算漫反射
				fixed halfLambert = 0.5*dot(worldNormal,worldLightDir)+0.5;//半兰伯特模型
				//fixed halfLambert = max(0,dot(worldNormal,worldLightDir));
				fixed3 diffuseColor = tex2D(_RampTex,fixed2(halfLambert,halfLambert)).rgb*_Color.rgb;//将采样到的颜色和材质球上的属性_Color颜色相乘
				fixed3 diffuse = _LightColor0.rgb*diffuseColor;//光颜色*diffuseColor的漫反射颜色
				//下面计算高光
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(worldLightDir+viewDir);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
				return fixed4(diffuse+specular,1.0);
			}
			ENDCG
		}
		
	} 
	FallBack "Specular"
}

