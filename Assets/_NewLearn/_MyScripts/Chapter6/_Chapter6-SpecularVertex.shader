// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Learn/Chapter6/_SpecularVertex"
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
				fixed3 color:TEXCOORD0;
			};

			fixed4 _Specular;
			float _Gloss;
			fixed4 _Diffuse;

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				fixed3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));//模型该点在世界坐标下的光源方向
				fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));//点在世界空间下的法线
				fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));//光反射方向
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-mul(unity_ObjectToWorld,v.vertex));//视角方向
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate( dot(reflectDir,viewDir)),_Gloss);
				fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLightDir));

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				o.color = ambient+diffuse+specular;
				return o;
			}

			fixed4 frag(v2f i):SV_Target
			{
				return fixed4(i.color,1.0);
			}
			ENDCG
		}
	}
	FallBack "Specular"
}