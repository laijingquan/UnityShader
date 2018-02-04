Shader "MyShader/Chapter6第二次练习/DiffuseVertexLevel" 
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
					fixed3 color:COLOR;
				};

				v2f vert(a2v v)
				{
					v2f o;
					o.pos = mul(UNITY_MATRIX_MVP,v.vertex);

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//环境光

					fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));//法线从模型空间变换到世界空间
					fixed3 worldLightDir = WorldSpaceLightDir(o.pos);//用内置函数计算在世界空间下,该点到光源的方向
					fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLightDir));//漫反射计算公式
					o.color = ambient+diffuse;
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

