Shader "MyShader/Chapter6第二次练习/SpecularVertexLevel" {
	Properties {
		_Diffuse("Diffuse",Color)=(1,1,1,1)
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
				fixed3 color:COLOR;//这里在顶点着色器计算好颜色,传给片元,然后输出即可
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//环境光
				fixed3 worldLightDir = WorldSpaceLightDir(v.vertex);
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*max(0,dot(normalize(worldNormal),normalize(worldLightDir)));//计算漫反射

				fixed3 viewDir = WorldSpaceViewDir(v.vertex);//世界空间下视角方向
				fixed3 reflectDir = reflect(-worldLightDir,worldNormal);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(normalize(viewDir),normalize(reflectDir))),_Gloss);//高光反射

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
	FallBack "Diffuse"
}

