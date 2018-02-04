Shader "MyShader/Chapter7/SingleTexture" {
	Properties{
		_Color("Color Tint",Color) = (1,1,1,1)
		_MainTex("Main Text",2D) = "while"{}
		_Specular("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(8.0,256))=20
	}

	SubShader{
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex MyVert
			#pragma fragment MyFrag

			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;//纹理名_ST的方式来声明某个纹理的属性，ST是缩放(Scale)和平移(translation)的缩写,_MainText_ST.xy是缩放值,_MainText_ST.zw存储的是偏移值
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
				float4 vertex:POSITION;//将模型的顶点坐标填充到vertex
				float3 normal:NORMAL;//将模型的法线向量填充到normal
				float4 texcoord:TEXCOORD0;//将模型的第一组纹理坐标填充到texcoord
			};

			struct v2f{
				float4 pos:SV_POSITION;
				float3 worldNormal:TEXCOORD0;
				float3 worldPos:TEXCOORD1;
				float2 uv:TEXCOORD2;
			};

			v2f MyVert(a2v v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				o.uv = v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
				//or just call the build-in function第一个参数是顶点纹理坐标,第二个坐标是纹理名
				//o.uv = TRANSOFORM_TEX(v.texcoord,_MainTex);
				return o;
			}

			fixed4 MyFrag(v2f i):SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				//Use the texture to sample the diffuse color
				fixed3 albedo =tex2D(_MainTex,i.uv).rgb*_Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
				fixed3 diffuse = _LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLightDir));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(worldLightDir+viewDir);
				fixed3 specular= _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
				return fixed4(ambient+diffuse+specular,1.0);
			}
			ENDCG
		}
	}
	FallBack "Specular"
}

