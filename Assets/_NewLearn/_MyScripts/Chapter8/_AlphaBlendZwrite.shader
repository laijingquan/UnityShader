Shader "Learn/Chapter8/_AlphaBlendZWrite"
{
	Properties{
		_Color("Color Tint",Color)=(1,1,1,1)
		_MainTex("Main Tex",2D)="while"{}
		_AlphaScale("AlphaScale",Range(0,1))=1
		_Specular("Specular",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(0,256)) =20 
	}

	SubShader
	{
		Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

		Pass
		{
			Tags{"LightMode"="ForwardBase"}

			//ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			fixed4 _Color;
			fixed4 _Specular;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _AlphaScale;
			float _Gloss;

			struct a2v
			{
				float4 vertex:POSITION;
				float3 normal:NORMAL;
				float4 texcoord:TEXCOORD0;
			};

			struct v2f
			{
				float4 pos:SV_POSITION;
				float3 worldNormal:TEXCOORD0;
				float3 worldPos:TEXCOORD1;
				float2 uv:TEXCOORD3;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				//模型空间的法线变换到世界空间 需要的矩阵是 模型->世界 矩阵 逆的转置
				// Mv = v的转置 乘以 M的转置 mul(M,v) = mul(v的转置,M的转置)
				//o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
				o.uv = v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				return o;
			}

			fixed4 frag(v2f i):SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 viewDir = normalize(fixed3(_WorldSpaceCameraPos.xyz-i.worldPos));
				fixed4 texColor = tex2D(_MainTex,i.uv);
				//Alpha test
				//clip(texColor.a-_Cutoff);
				//if((texColor.a-_Cutoff)<0)
					//discard;
				fixed3 albedo = texColor.rgb*_Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;//防止没有漫反射时，背面只有UNITY_LIGHTMODEL_AMBIENT.xyz
				fixed3 diffuse = _LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLightDir));
				fixed3 halfDir = normalize(viewDir+worldLightDir);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
				return fixed4(ambient+diffuse+specular,texColor.a*_AlphaScale);
			}
			ENDCG
		}
	}
	FallBack "Transparent/Cutout/VertexLit"
}
