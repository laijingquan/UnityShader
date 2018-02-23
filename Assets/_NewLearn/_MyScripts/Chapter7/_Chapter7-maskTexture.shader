// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Learn/Chapter7/_MaskTexture"
{
	Properties{
		_Specular("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(8.0,256))=20
		//_Diffuse("Diffuse",Color)=(1,1,1,1)
		_DiffuseColor("Color",Color)=(1,1,1,1)
		_MainTex("MainTex",2D)="while"{}
		_BumpTex("BumpTex",2D)="bump"{}
		_BumpScale("BumpScale",float) = 1.0

		_SpecularMask("Specular Mask",2D)="while"{}
		_SpecularScale("Specular Scale",Float) = 1.0
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

			struct a2v
			{
				float4 vertex:POSITION;//模型顶点填充到vertex变量
				float3 normal:NORMAL;//模型法线填充到normal变量
				float4 texcoord:TEXCOORD0;//模型第一组纹理坐标填充到texcoord变量
				float4 tangent:TANGENT;//模型顶点的切线，用于和顶点法线构成顶点的切线空间
			};
			struct v2f
			{
				float4 pos:SV_POSITION;
				float3 tangentViewDir:TEXCOORD0;//在顶点着色器计算好切线空间下的视角方向
				float3 tangentLightDir:TEXCOORD1;//在顶点着色器上计算好切线空间下的光照方向
				float4 uv:TEXCOORD2;
			};

			fixed4 _Specular;
			float _Gloss;
			fixed4 _DiffuseColor;
			sampler2D _MainTex;
			sampler2D _BumpTex;//新增了法线纹理
			float _BumpScale;
			float4 _MainTex_ST;
			float4 _BumpTex_ST;//同理要有法线纹理的缩放和偏移属性

			sampler2D _SpecularMask;//高光遮罩，控制高光细节
			float _SpecularScale;//控制遮罩的影响程度

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				float3x3 objectToTangentMatrix = float3x3(v.tangent.xyz,cross(v.normal,v.tangent.xyz)*v.tangent.w,v.normal);//构造模型空间到切线空间的变换矩阵
				o.tangentViewDir = mul(objectToTangentMatrix,ObjSpaceViewDir(v.vertex));//视角方向
				o.tangentLightDir = mul(objectToTangentMatrix,ObjSpaceLightDir(v.vertex));//光照方向
				o.uv.xy = v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
				o.uv.zw =v.texcoord.xy*_BumpTex_ST.xy+_BumpTex_ST.zw;
				return o;
			}

			fixed4 frag(v2f i):SV_Target
			{
				fixed3 tangentLightDir = normalize(i.tangentLightDir);//模型该点在切线空间坐标下的光源方向
				//fixed3 worldNormal = normalize(i.worldNormal);//点在世界空间下的法线
				//fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));//光反射方向

				fixed4 packedNormal = tex2D(_BumpTex,i.uv.zw);//采样法线的xy分量,要自己求z分量
				fixed3 tangentNormal;
				//不是Normal Map纹理类型,xy这样解出来
				{
					//tangentNormal.xy = (packedNormal.xy*2-1)*_BumpScale;
				}
				//如果 纹理在unity中设置了NormalMap 那么就用内置函数来解开
				{
					tangentNormal = UnpackNormal(packedNormal);
					tangentNormal.xy*=_BumpScale;
				}

				tangentNormal.z = sqrt(1-saturate(dot(tangentNormal.xy,tangentNormal.xy)));//根据单位向量的模为1求出z

				fixed3 tangentViewDir = normalize(i.tangentViewDir);//视角方向
				fixed3 halfDir = normalize(tangentViewDir+tangentLightDir);//Blinn-Phong光照模型

				fixed specularMask = tex2D(_SpecularMask,i.uv).r*_SpecularScale;//采样遮罩纹理

				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate( dot(tangentNormal,halfDir)),_Gloss)*specularMask;//Blinn-Phong光照模型+遮罩控制高光细节

				fixed3 albedo = tex2D(_MainTex,i.uv.xy)*_DiffuseColor.rgb;//用纹理颜色代替漫反射材质颜色

				fixed3 diffuse = _LightColor0.rgb*albedo.rgb*saturate(dot(tangentNormal,tangentLightDir));

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;//如果没有自然光，那么背面没有光照的地方就是一片黑的
				//fixed3 color = ambient+diffuse+specular;
				fixed3 color = specular;//只保留高光 是为了更好的观察遮罩纹理造成的影响
				return fixed4(color,1.0);
			}
			ENDCG
		}
	}
	FallBack "Specular"
}