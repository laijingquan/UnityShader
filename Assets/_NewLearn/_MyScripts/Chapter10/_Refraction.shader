﻿Shader "Learn/Chpater10/_Refraction" 
{
	Properties 
	{
		_Color ("Color控制漫反射颜色", Color) = (1,1,1,1)
		_RefractColor("Color控制折射颜色",Color)=(1,1,1,1)//控制折射颜色
		_RefractAmount("Reflect Amount控制折射程度",Range(0,1))=1//控制折射程度
		_RefractRatio("介质透射比",Range(0.1,1))=0.5
		_Cubemap("Reflection Cuebemap",Cube)="_Skybox"{}
	}

	SubShader
	{
		Tags{"RenderType"="Opaque" "Queue"="Geometry"}
		Pass
		{
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
			fixed4 _RefractColor;
			fixed _RefractAmount;
			fixed _RefractRatio;
			samplerCUBE _Cubemap;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				fixed3 worldNormal : TEXCOORD1;
				fixed3 worldViewDir : TEXCOORD2;
				fixed3 worldRefra : TEXCOORD3;
				SHADOW_COORDS(4)
			};

			v2f vert(a2v v) 
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.worldRefra = refract(-normalize(o.worldViewDir),normalize(o.worldNormal),_RefractRatio);
				TRANSFER_SHADOW(o);
				return o;
				
				return o;
			}

			fixed4 frag(v2f i) : SV_Target 
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldViewDir = normalize(i.worldViewDir);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 diffuse = _LightColor0.rgb*_Color.rgb*max(0,dot(worldNormal,worldLightDir));

				fixed3 refraction = texCUBE(_Cubemap,i.worldRefra).rgb*_RefractColor;
				UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
				fixed3 color = ambient+lerp(diffuse,refraction,_RefractAmount);//_ReflectAmount为1代表完全用cubemap代替漫反射光，为0，完全么有CubeMap采样
				//fixed3 color = ambient+diffuse;
				return fixed4(color,1.0);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
