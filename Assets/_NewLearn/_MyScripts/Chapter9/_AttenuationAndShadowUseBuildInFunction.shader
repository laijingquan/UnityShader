Shader "Learn/Chpater9/_AttenuationAndShadowUseBuildInFunctions" {
	Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader
	{
		Tags{"RenderType"="Opaque"}
		Pass
		{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
				float4 vertex:POSITION;
				float3 normal:NORMAL;
			};

			struct v2f{
				float4 pos:SV_POSITION;
				float3 worldPos:TEXCOORD0;
				float3 worldNormal:TEXCOORD1;
				SHADOW_COORDS(2)
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
				TRANSFER_SHADOW(o);//根据提供模型顶点计算对应的阴影纹理坐标，用于在片元里采样。
				//o.worldNormal = UnityObjectToWorldNormal(v.normal);
				return o;
			}
			//自然光+漫反射+高光
			fixed4 frag(v2f i):SV_Target
			{
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 worldNormal = normalize(i.worldNormal);
				//平行光 他就是方向,其他光源类型，那就是位置变量。（Base pass中 我们处理的都是平行光，所以_WorldSpaceLightPos0就是方向）
				fixed3 worldLightDir =normalize(_WorldSpaceLightPos0.xyz);
				fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*max(0,dot(worldNormal,worldLightDir));
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir+viewDir);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow((max(0,dot(worldNormal,halfDir))),_Gloss);
				//fixed atten = 1.0;
				//fixed shadow = SHADOW_ATTENUATION(i);//采样阴影纹理
				//传变量i,是用于采样阴影纹理,传i.worldPos是用于计算光照衰减
				UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);//用内置函数 同时采样阴影纹理和计算光照衰减，两者结果相乘返回给atten
				return fixed4(ambient+(diffuse+specular)*atten,1.0);
			}
			ENDCG
		}
		Pass
		{
				Tags{"LightMode"="ForwardAdd"}
				Blend One One
				CGPROGRAM
				#pragma multi_compile_fwdadd
				#pragma vertex vert
				#pragma fragment frag
				#include "Lighting.cginc"
				#include "AutoLight.cginc"

				fixed4 _Diffuse;
				fixed4 _Specular;
				float _Gloss;

				struct a2v{
					float4 vertex:POSITION;
					float3 normal:NORMAL;
				};

				struct v2f{
					float4 pos:SV_POSITION;
					float3 worldPos:TEXCOORD0;
					float3 worldNormal:TEXCOORD1;
				};

				v2f vert(a2v v)
				{
					v2f o;
					o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
					o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
					o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
					//o.worldNormal = UnityObjectToWorldNormal(v.normal);
					return o;
				}
				//自然光+漫反射+高光
				fixed4 frag(v2f i):SV_Target
				{
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
					fixed3 worldNormal = normalize(i.worldNormal);
					//平行光 他就是方向,其他光源类型，那就是位置变量。（Base pass中 我们处理的都是平行光，所以_WorldSpaceLightPos0就是方向）
					//#ifdef USING_DIRECTIONAL_LIGHT
					//	fixed3 worldLightDir =normalize(_WorldSpaceLightPos0.xyz);
					//#else
					//	fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz-i.worldPos.xyz);
					//#endif
					fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));//这样算更通用

					fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*max(0,dot(worldNormal,worldLightDir));
					fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
					fixed3 halfDir = normalize(worldLightDir+viewDir);
					fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow((max(0,dot(worldNormal,halfDir))),_Gloss);
					//#ifdef USING_DIRECTIONAL_LIGHT
					//	fixed atten = 1.0;
					//#else
					//	#if defined (POINT)
					//		float3 lightCoord = mul(unity_WorldToLight,float4(i.worldPos,1)).xyz;
					//		fixed atten = tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
					//	#elif defined (SPOT)
					//		float4 lightCoord = mul(unity_WorldToLight,float(i.worldPos,1));
					//		fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
					//	#else
					//		fixed atten = 1.0;
					//	#endif
					//#endif
					UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);//用内置函数 同时采样阴影纹理和计算光照衰减，两者结果相乘返回给atten
					return fixed4(ambient+(diffuse+specular)*atten,1.0);
				}
				ENDCG
		}
	}
	FallBack "Specular"
}
