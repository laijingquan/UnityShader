Shader "MyShader/Chapter6/SpecularPixelLevel" {
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
				float3 worldNormal:TEXCOORD0;
				float3 worldPos:TEXCOORD1;
			};

			v2f MyVert(a2v v)
			{
				v2f o;
				//Transform the vertex from object space to world sapce
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);

				//Transform the vertex normal from object space to world space
				o.worldNormal =  mul(v.normal,(float3x3)unity_WorldToObject);

				o.worldPos = mul(unity_ObjectToWorld,v.vertex);


				return o;
			}

			fixed4 MyFrag(v2f i):SV_Target
			{
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				//Get the light direction in world space
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*saturate(dot(normalize(i.worldNormal),worldLightDir));
				//Get the reflect direction in world space
				fixed3 reflectDir = normalize(reflect(-worldLightDir,i.worldNormal));
				//Get the view direction in world space
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-normalize(i.worldPos));
				//Compute Specular term
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate(dot(viewDir,reflectDir)),_Gloss);

				fixed3 color = ambient+specular;

				return fixed4(color,1.0);
			}
			ENDCG
		}
	}

	FallBack "Specular"
}
