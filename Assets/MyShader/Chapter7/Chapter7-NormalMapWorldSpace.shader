Shader "MyShader/Chapter7/NormalMapWorldSpace" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale",Float)=1.0
		_Specular("Specular",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8,256))=20
	}
	SubShader {
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex myvert
			#pragma fragment myfrag
			#include "Lighting.cginc"
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;

			//收集模型的各种数据
			struct a2v
			{
				float4 vertex:POSITION;//顶点填充
				float3 normal:NORMAL;//顶点法线填充
				float4 tangent:TANGENT;//顶点切线填充
				float4 texcoord:TEXCOORD0;//纹理坐标	
			};
			struct v2f{
				float4 pos:SV_POSITION;//渲染引擎会把用SV_POSITION修饰的变量经过光栅化后显示在屏幕上
				float4 uv:TEXCOORD0;//用于采样的纹理坐标,这里范围不一定在[0,1],超过范围的根据wrapMode方式来处理
				float4 TtoW0:TEXCOORD1;
				float4 TtoW1:TEXCOORD2;
				float4 TtoW2:TEXCOORD3;
			};

			v2f  myvert(a2v v)
			{
				v2f  o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				o.uv.xy = v.texcoord.xy*_MainTex_ST+_MainTex_ST.zw;//_MainTex纹理的uv经过缩放平移后存储到o.uv.xy
				o.uv.zw=v.texcoord.xy*_MainTex_ST+_MainTex_ST.zw;//_BumpMap法线纹理的uv经过缩放平移后存储到o.uv.zw

				float3 worldPos = mul(unity_ObjectToWorld,v.vertex);//计算顶点在世界空间的位置,在片元着色器计算光照方向和视角方向要用到(unity内置函数的输入)
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);//将切线从模型空间转换到世界空间,tangent.w的也是有用处的,用来确定副切线的方向
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);//将法线从模型空间转换到世界空间中
				fixed3 worldBinormal = cross(worldTangent,worldNormal)*v.tangent.w;//计算副切线

				//构建切线空间到世界空间的变换矩阵
				o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
				o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
				o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);
				return o;
			}

			fixed4 myfrag(v2f i):SV_Target
			{
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				//对法线贴图纹理采样
				fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);
				fixed3 bump = UnpackNormal(packedNormal);
				bump.xy*=_BumpScale;
				bump.z = sqrt(1.0-saturate(dot(bump.xy,bump.xy)));
				bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));

				fixed3 albedo = tex2D(_MainTex,i.uv).rgb*_Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;//计算自然光
				fixed3 diffuse = _LightColor0.rgb*albedo*max(0,dot(bump,lightDir));//计算漫反射
				fixed3 halfDir = normalize(lightDir+viewDir);
				fixed3 specular = _LightColor0.rgb*_Specular*pow(max(0,dot(bump,halfDir)),_Gloss);
				return fixed4(ambient+diffuse+specular,1.0);
			}
			ENDCG
		}
	} 
	FallBack "Specular"
}