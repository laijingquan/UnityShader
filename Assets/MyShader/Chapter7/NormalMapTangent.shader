Shader "MyShader/Chapter7/NormalMapTangentSpace" {
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
				float3 lightDir:TEXCOORD1;//在顶点着色器将在切线空间下的光照方向计算好,填充之
				float3 viewDir:TEXCOORD2;//在顶点着色器将在切线空间下的视角方向计算好,填充之
			};

			v2f  myvert(a2v v)
			{
				v2f  o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				o.uv.xy = v.texcoord.xy*_MainTex_ST+_MainTex_ST.zw;//_MainTex纹理的uv经过缩放平移后存储到o.uv.xy
				o.uv.zw=v.texcoord.xy*_MainTex_ST+_MainTex_ST.zw;//_BumpMap法线纹理的uv经过缩放平移后存储到o.uv.zw
				//compute the binormal 副切线,这里是为了构建模型空间到切线空间的变换矩阵
				float3 binormal = cross(normalize(v.normal),normalize(v.tangent.xyz))*v.tangent.w;
				//Construct a matrix which transform vectors from object space to tangent space 构建矩阵数学原理详见4.6.2节
				float3x3 rotation = float3x3(v.tangent.xyz,binormal,v.normal);

				//Transform the light direction from object space to tangent space将光照方向从模型空间转换到切线空间
				o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
				//Transform the view direction frome object space to tangent space将视角方向从模型空间转换到切线空间
				o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;
				return o;
			}

			fixed4 myfrag(v2f i):SV_Target
			{
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				//对法线贴图纹理采样
				fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);

				fixed3 tangentNormal;
				//tangentNormal.xy =(PackedNormal.xy*2-1)*_BumpScale;
				//当我们在unity选中纹理类型为Normal map,unity会将其压缩,所以自己计算可能会出错,这里用unity提供的api来映射回[0,1]范围
				tangentNormal.xy = UnpackNormal(packedNormal);
				tangentNormal.xy*=_BumpScale;
				tangentNormal.z = sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));

				fixed3 albedo = tex2D(_MainTex,i.uv).rgb*_Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;//计算自然光
				fixed3 diffuse = _LightColor0.rgb*albedo*max(0,dot(tangentNormal,tangentLightDir));//计算漫反射
				fixed3 halfDir = normalize(tangentLightDir+tangentViewDir);
				fixed3 specular = _LightColor0.rgb*_Specular*pow(max(0,dot(tangentNormal,halfDir)),_Gloss);
				return fixed4(ambient+diffuse+specular,1.0);
			}
			ENDCG
		}
	} 
	FallBack "Specular"
}