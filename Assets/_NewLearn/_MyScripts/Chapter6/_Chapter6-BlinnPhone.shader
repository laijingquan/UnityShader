// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Learn/Chapter6/_BlinnPhone"
{
	Properties{
		_Specular("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(8.0,256))=20
		_Diffuse("Diffuse",Color)=(1,1,1,1)
	}

	SubShader
	{	
		Pass
		{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"

			struct a2v
			{
				float4 vertex:POSITION;
				float3 normal:NORMAL;
			};
			struct v2f
			{
				float4 pos:SV_POSITION;
				float4 worldPos:TEXCOORD0;
				float3 worldNormal:TEXCOORD1;
			};

			fixed4 _Specular;
			float _Gloss;
			fixed4 _Diffuse;

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
				return o;
			}

			fixed4 frag(v2f i):SV_Target
			{
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));//模型该点在世界坐标下的光源方向
				fixed3 worldNormal = normalize(i.worldNormal);//点在世界空间下的法线
				//fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));//光反射方向
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos);//视角方向
				fixed3 halfDir = normalize(viewDir+worldLightDir);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate( dot(worldNormal,halfDir)),_Gloss);
				fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLightDir));

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 color = ambient+specular;
				return fixed4(color,1.0);
			}
			ENDCG
		}
	}
	FallBack "Specular"
}