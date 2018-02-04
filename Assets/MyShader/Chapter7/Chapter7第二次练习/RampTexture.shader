Shader "MyShader/Chapter7第二次练习/RampTexture" {
	Properties {
		_MainTex("纹理",2D)="white"{}
		_Color("Diffuse",Color)=(1,1,1,1)
		_Specular ("Specular Color", Color) = (1,1,1,1)
		_Gloss("Gloss",Range(8.0,256))=20
	}
	SubShader {
		pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"

			fixed4 _Specular;
			float _Gloss;
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;

			struct a2v
			{
				float4 vertex:POSITION;
				float3 normal:NORMAL;
				float4 texcoord:TEXCOORD0;//获取该点纹理坐标	
			};

			struct v2f
			{
				float4 pos:SV_POSITION;
				float3 worldNormal:TEXCOORD0;//这里并不是一个顶点对应一个片元,这里可能是插值过来的法线（插值细节没有深入）
				float3 worldPos:TEXCOORD1;//同理,插值得到的顶点,这里传顶点可以在下个阶段做更多事情,这里的作用是计算光照方向了(当然还有其他的作用),所以传顶点是有道理的
				float2 uv:TEXCOORD2;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				o.uv = v.texcoord*_MainTex_ST.xy+_MainTex_ST.zw;
				return o;
			}

			fixed4 frag(v2f i):SV_Target
			{
				fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPos);
				fixed halfLambert = 0.5*dot(normalize(i.worldNormal),normalize(worldLightDir))+0.5;
				fixed3 albedo = tex2D(_MainTex,fixed2(halfLambert,halfLambert)).rgb*_Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//环境光

				fixed3 diffuse = _LightColor0.rgb*albedo;//计算漫反射

				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));//世界空间下视角方向

				fixed3 halfDir = normalize(viewDir+worldLightDir);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(normalize(i.worldNormal),halfDir)),_Gloss);//高光反射

				return fixed4(ambient+diffuse+specular,1.0);
			}
			ENDCG
		}
	} 
	FallBack "Diffuse"
}

