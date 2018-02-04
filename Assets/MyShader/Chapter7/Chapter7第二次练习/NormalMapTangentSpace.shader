Shader "MyShader/Chapter7第二次练习/NormalMapTangentSpace" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Bump (RGB) Illumin (A)", 2D) = "bump" {}
		_BumpScale("bumpScale",Float)=1.0
		_Specular("Specular",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8.0,256))=20
	}
	SubShader {
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;
			struct a2v
			{
				float4 vertex:POSITION;
				float3 normal:NORMAL;
				float4 tangent:TANGENT;
				float4 texcoord:TEXCOORD0;
			};

			struct v2f
			{
				float4 pos:SV_POSITION;
				float3 viewDir:TEXCOORD0;
				float3 lightDir:TEXCOORD1;
				float4 uv:TEXCOORD2;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				o.uv.xy = v.texcoord*_MainTex_ST.xy+_MainTex_ST.zw;
				o.uv.zw = v.texcoord*_BumpMap_ST.xy+_BumpMap_ST.zw;
				float3 binormal = cross(normalize(v.normal),normalize(v.tangent.xyz))*v.tangent.w;
				float3x3 rotation = float3x3(v.tangent.xyz,binormal,v.normal);
				o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;
				o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
				return o;
			}

			fixed4 frag(v2f i):SV_Target
			{
				fixed3 tangentViewDir = normalize(i.viewDir);
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);
				fixed3 tangentNormal;
				tangentNormal.xy = UnpackNormal(packedNormal)*_BumpScale;
				tangentNormal.z = sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));
				fixed3 albedo = tex2D(_MainTex,i.uv).rgb*_Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT*albedo;
				fixed3 diffuse = _LightColor0.rgb*albedo*saturate(dot(tangentNormal,tangentViewDir));
				fixed3 halfDir = normalize(tangentViewDir+tangentLightDir);
				fixed3 Specular = _LightColor0.rgb*_Specular.rgb*pow(saturate(dot(tangentNormal,halfDir)),_Gloss);
				return fixed4(ambient+diffuse+Specular,1.0);
			}
			ENDCG
		}
	} 
	FallBack "Specular"
}

