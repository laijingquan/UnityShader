Shader "MyShader/Chapter6第二次练习/DiffusePixelLevel" 
{
	Properties
	{
		_Diffuse("Diffuse",Color) = (1,1,1,1)
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
				fixed4 _Diffuse;

				struct a2v{
					float4 vertex:POSITION;
					float3 normal:NORMAL;
				};
				struct v2f{
					float4 pos:SV_POSITION;
					float3 normal:TEXCOORD0;
					float4 worldPos:TEXCOORD1;
				};

				v2f vert(a2v v)
				{
					v2f o;
					o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
					o.normal = mul(v.normal,(float3x3)unity_WorldToObject);//法线从模型空间变换到世界空间,传到片元再归一化,因为我们有可能在片元那边需要没有归一化的法线
					o.worldPos = mul(unity_WorldToObject,v.vertex); 
					return o;
				}

				fixed4 frag(v2f i):SV_Target
				{
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//环境光

					fixed3 worldLightDir = WorldSpaceLightDir(i.worldPos);//用内置函数计算在世界空间下,该点到光源的方向
					fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*saturate(dot(normalize(i.normal),normalize(worldLightDir)));//漫反射计算公式
					fixed3 color = ambient+diffuse;
					return fixed4(color,1.0);
				}
				ENDCG
			}
		}
	FallBack "Diffuse"
}

