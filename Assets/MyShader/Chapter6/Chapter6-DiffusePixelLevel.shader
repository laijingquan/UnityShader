Shader "MyShader/Chapter6/Diffuse Pixel-Level"{
	Properties{
		_Diffuse("Diffuse",Color)=(1,1,1,1)
	}
	SubShader
	{
		Pass
		{
			Tags{"LightMode"="ForwardBase"}
		
			CGPROGRAM
			#pragma vertex Myvert
			#pragma fragment Myfrag
			#include "Lighting.cginc"
			fixed4 _Diffuse;
			struct a2v{
				float4 vertex:POSITION;
				float3 normal:NORMAL;

			};
			struct v2f{
				float4 pos:SV_POSITION;
				float3 worldNormal:TEXCOORD0;
			};
			v2f Myvert(a2v v)
			{
				v2f o;
				//Transform the vertex from object space to projection space
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);

				//Transform the nomal form object sapce to world space
				o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
				return o;
			}

			fixed4 Myfrag(v2f i):SV_Target
			{
				//Get ambient term
				fixed3 ambient= UNITY_LIGHTMODEL_AMBIENT.xyz;

				//Get the light direction in world space
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*saturate(dot(i.worldNormal,worldLightDir));
				fixed3 color = ambient+diffuse;
				return fixed4(color,1.0);
			}

			ENDCG
		}
	}
	Fallback "Diffuse"
}