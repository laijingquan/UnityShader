Shader "MyShader/Chapter9/AlphaTestWithShadow" {
	Properties {
		_Color ("Main Tint", Color) = (1,1,1,1)
		_MainTex ("MainTex", 2D) = "white" {}
		_Cutoff("Alpha Cutoff",Range(0,1))=0.5
	}
	SubShader {
		Tags{"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
			pass{
				Tags{"LightMode"="ForwardBase"}
				CGPROGRAM
				#pragma multi_compile_fwdbase
				#pragma vertex vert
				#pragma fragment frag
				#include "Lighting.cginc"
				#include "AutoLight.cginc"
				fixed4 _Color;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				fixed _Cutoff;

				struct a2v
				{
					float4 vertex:POSITION;//TRANSFER_SHADOW使用需要我们保证a2v结构中的顶点坐标变量必须为vertex,v2f变量命名必须为o（和书中202页的描述有出入,我认为书中描述错误），v2f中顶点变量必须命名为pos
					float3 normal:NORMAL;
					float4 texcoord:TEXCOORD0;

				};

				struct v2f{
					float4 pos:SV_POSITION;
					float3 worldNormal:TEXCOORD0;
					float3 worldPos:TEXCOORD1;
					float2 uv:TEXCOORD2;
					SHADOW_COORDS(3)//因为插值存储器已经占了3个了,所以这里索引3(第四个)的插值存储器
				};

				v2f vert(a2v v)
				{
					v2f o;
					o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
					o.worldNormal = UnityObjectToWorldNormal(v.normal);
					o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
					o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
					//传递阴影纹理坐标到片元着色器
					TRANSFER_SHADOW(o);
					return o;
				}

				fixed4 frag(v2f i):SV_Target
				{
					fixed3 worldNormal = normalize(i.worldNormal);
					fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

					fixed4 texColor = tex2D(_MainTex,i.uv);
					clip(texColor.a-_Cutoff);
					fixed3 albedo = texColor.rgb*_Color.rgb;
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
					fixed3 diffuse = _LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLightDir));
					//计算阴影和光照衰减
					UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
					return fixed4(ambient+diffuse*atten,1.0);
				}
				ENDCG
			}
	} 
	FallBack "Transparent/Cutout/VertexLit"
}

