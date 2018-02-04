Shader "MyShader/Chapter6/SpecularVertexLevel" {
	Properties{
		_Diffuse("Diffuse",Color)=(1,1,1,1)
		_Specular("Specular",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8.0,256))=20
	}
	SubShader{
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex MyVert
			#pragma fragment MyFrag
			#include "Lighting.cginc"
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct a2v
			{
				float4 vertex:POSITION;
				float3 normal:NORMAL;
			};

			struct v2f
			{
				float4 pos:SV_POSITION;
				fixed3 color:COLOR;
			};

			v2f MyVert(a2v v)
			{
				v2f o;
				//Transform the vertex from object space to world sapce
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				//Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				//Transform the vertex normal from object space to world space
				fixed3 worldNormal = normalize( mul(v.normal,(float3x3)unity_WorldToObject));
				//Get the light direction in world space
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLightDir));
				//Get the reflect direction in world space
				fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
				//Get the view direction in world space
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-mul(unity_ObjectToWorld,v.vertex));
				//Compute Specular term
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate(dot(viewDir,reflectDir)),_Gloss);

				o.color = ambient+specular;
				return o;
			}

			fixed4 MyFrag(v2f i):SV_Target
			{
				return fixed4(i.color,1.0);
			}
			ENDCG
		}
	}

	FallBack "Specular"
}
