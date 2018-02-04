Shader "MyShader/Chapter6/HalfLambert Vertex-Level"{
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
				fixed3 color:COLOR;
			};
			v2f Myvert(a2v v)
			{
				v2f o;
				//Transform the vertex from object space to projection space
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				//Get ambient term
				fixed ambient= UNITY_LIGHTMODEL_AMBIENT.xyz;

				//Transform the normal from object space to world space
				fixed3 worldNormal = mul(transpose((float3x3)unity_WorldToObject),v.normal);
				//Get the light direction in world space
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				//Compute diffuse term
				fixed3 halfLambert = dot(worldNormal,worldLight)*0.5+0.5;
				fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*halfLambert;
				o.color = ambient+diffuse;
				return o;
			}

			fixed4 Myfrag(v2f i):SV_Target{
				return fixed4(i.color,1.0);
			}

			ENDCG
		}
	}
	Fallback "Diffuse"
}