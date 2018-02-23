// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Learn/Chapter7/_RampTexture"
{
	Properties{
		_Specular("Specular",Color) = (1,1,1,1)//高光反射材质颜色
		_Gloss("Gloss",Range(8.0,256))=20
		//_Diffuse("Diffuse",Color)=(1,1,1,1)
		_DiffuseColor("Color",Color)=(1,1,1,1)//漫反射材质颜色
		_MainTex("MainTex",2D)="while"{}
		//_BumpTex("BumpTex",2D)="bump"{}
		//_BumpScale("BumpScale",float) = 1.0
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
				//float4 tangent:TANGENT;//模型顶点的切线，用于和顶点法线构成顶点的切线空间
			};
			struct v2f
			{
				float4 pos:SV_POSITION;
				//float4 TtoW0:TEXCOORD0;//切线空间到世界空间的第一行
				//float4 TtoW1:TEXCOORD1;//切线空间到世界空间的第二行
				//float4 TtoW2:TEXCOORD2;//切线空间到世界空间的第三行
				float3 worldNormal:TEXCOORD0;
				float2 uv:TEXCOORD1;
				float3 worldPos:TEXCOORD2;
			};

			fixed4 _Specular;
			float _Gloss;
			fixed4 _DiffuseColor;
			sampler2D _MainTex;
			//sampler2D _BumpTex;//新增了法线纹理
			//float _BumpScale;
			float4 _MainTex_ST;
			//float4 _BumpTex_ST;//同理要有法线纹理的缩放和偏移属性

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				//float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				//fixed3 worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);//切线空间的法线在世界空间下的表示
				 o.worldPos  = mul(unity_ObjectToWorld,v.vertex).xyz;
				 o.worldNormal = UnityObjectToWorldNormal(v.normal);
				//fixed3 worldTangent = mul((float3x3)unity_ObjectToWorld,v.tangent.xyz);//切线空间的切线在世界空间下的表示
				//fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				//fixed3 worldBiTangent = cross(worldNormal,worldTangent)*v.tangent.w;//切线空间的副切线在世界空间下的表示
				//那么有如上三个向量 我们就可以构造切线空间到世界空间的变换矩阵(CG是按行来读和存 矩阵的每一位)
				//o.TtoW0 = float4(worldTangent.x,worldBiTangent.x,worldNormal.x,worldPos.x);
				//o.TtoW1 = float4(worldTangent.y,worldBiTangent.y,worldNormal.y,worldPos.y);
				//o.TtoW2 = float4(worldTangent.z,worldBiTangent.z,worldNormal.z,worldPos.z);
				o.uv = v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
				//o.uv.zw =v.texcoord.xy*_BumpTex_ST.xy+_BumpTex_ST.zw;
				return o;
			}

			fixed4 frag(v2f i):SV_Target
			{
				//float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);//节省了寄存器得到顶点在世界空间下的表示
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));//视角方向
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));//模型该点在世界空间坐标下的光源方向
				//fixed3 worldNormal = normalize(i.worldNormal);//点在世界空间下的法线
				//fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));//光反射方向

				//fixed4 packedNormal = tex2D(_BumpTex,i.uv.zw);//采样法线的xy分量,要自己求z分量
				fixed3 worldNormal = normalize(i.worldNormal);
				//fixed3 tangentNormal;
				//不是Normal Map纹理类型,xy这样解出来
				{
					//tangentNormal.xy = (packedNormal.xy*2-1)*_BumpScale;
				}
				//如果 纹理在unity中设置了NormalMap 那么就用内置函数来解开
				//{
					//tangentNormal = UnpackNormal(packedNormal);
					//tangentNormal.xy*=_BumpScale;
				//}

				//tangentNormal.z = sqrt(1-saturate(dot(tangentNormal.xy,tangentNormal.xy)));//根据单位向量的模为1求出z

				//worldNormal = mul(float3x3(i.TtoW0.xyz,i.TtoW1.xyz,i.TtoW2.xyz),tangentNormal);//将切线空间下的法线转换到世界空间下

				//worldNormal = normalize(half3(dot(i.TtoW0.xyz,tangentNormal),dot(i.TtoW1.xyz,tangentNormal),dot(i.TtoW2.xyz,tangentNormal)));

				fixed3 halfDir = normalize(viewDir+worldLightDir);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate( dot(worldNormal,halfDir)),_Gloss);

				fixed halfLambert = 0.5*dot(worldNormal,worldLightDir)+0.5;
				//fixed halfLambert = saturate( dot(worldNormal,worldLightDir));
				fixed3 albedo = tex2D(_MainTex,fixed2(halfLambert,0)).rgb*_DiffuseColor.rgb;//不再用uv坐标去采样 而是采用halfLambert模式
				//albedo是渐变色
				fixed3 diffuse = _LightColor0.rgb*albedo.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//如果没有自然光，那么背面没有光照的地方就是一片黑的
				//fixed3 color = ambient+diffuse+specular;
				fixed3 color = diffuse;//只看漫反射 是为了更加容易地观察渐变纹理的采样
				return fixed4(color,1.0);
			}
			ENDCG
		}
	}
	FallBack "Specular"
}