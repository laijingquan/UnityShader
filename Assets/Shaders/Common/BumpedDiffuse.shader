// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
//完整的一个shader 包括了法线纹理,多光源,光照衰减和阴影相关处理
Shader "Unity Shaders Book/Common/Bumped Diffuse" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)//控制整体颜色
		_MainTex ("Main Tex", 2D) = "white" {}//用于代替漫反射颜色计算
		_BumpMap ("Normal Map", 2D) = "bump" {}//法线纹理
	}
	SubShader {
	//Background Geometry AlphaTest Transparent Overlay
	//1000				2000			2500				3000				4000
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}//渲染类型Opaque(不透明物体) 队列2000

		Pass { 
			//forwardbase 处理逐像素的一个平行光,如果有逐顶点的光源和SH光源 也是在Base Pass处理
			Tags { "LightMode"="ForwardBase" }//前向渲染路径中的forwardBase,必须设置 光照变量才会被填充 否则_LightColor0.rgb就是黑色
		
			CGPROGRAM
			
			#pragma multi_compile_fwdbase //前向渲染 必须的宏定义
			
			#pragma vertex vert	//定义顶点函数名
			#pragma fragment frag	//定义片元函数名
			
			#include "Lighting.cginc"	//包含头文件
			#include "AutoLight.cginc"	//包含头文件
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;// _MainTex+_ST(纹理名+Scale+Translation(缩放和位移))
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			
			struct a2v {
				float4 vertex : POSITION;//POSITION是语义,表明模型的顶点填充给vertex变量
				float3 normal : NORMAL;//NORMAL是语义,表明模型的法线填充给normal变量
				float4 tangent : TANGENT;//TANGENT是语义,表明模型的切线填充给tangent变量
				float4 texcoord : TEXCOORD0;//TEXCOORD0是语义,表明模型的纹理坐标填充给texcoord变量
			};
			
			struct v2f {
				float4 pos : SV_POSITION;//顶点着色器的最重要目标就是将在模型空间下的顶点转换到裁剪空间下的坐标
				float4 uv : TEXCOORD0;//顶点着色器计算好uv传递给片元，用于采样纹理
				//Unity采用的大多数是切线空间下的法线纹理，特征是图片看起来是蓝色，那是因为rgb的范围是0~1,而法线向量的方向是-1~1,我们最终是要存储到rgb里面,所以我们要映射过去就是normal*0.5+0.5就映射到0~1,因为切线空间下的法线大多数就是(0,0,1)转换成rgb存储就是(0.5,0.5,1)就是浅蓝色)
				//我们在计算光照的时候可以在切线空间下也可以在世界空间下计算，这里选择在切线空间下计算，所以要计算好切线空间->世界空间的矩阵
				//Tips:牢记 源空间下的3个标准正交基在目标空间下的表示为x,y,z ，那么x,y,z按列填充矩阵得到 ：原空间->目标空间的矩阵
				//我们知道切线空间下的3个标准正交基在世界空间下的表示，so 答案就出来了
				float4 TtoW0 : TEXCOORD1;//切线空间->世界矩阵  第一列
				float4 TtoW1 : TEXCOORD2;//第二列  
				float4 TtoW2 : TEXCOORD3;//第三列
				SHADOW_COORDS(4)//宏 声明阴影变量shadow
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);//顶点着色器最重要的一步,模型顶点转换到裁剪空间下
				
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;//根据材质变量来看是否需要缩放偏移uv
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;//根据材质变量来看是否需要缩放偏移uv
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; //模型顶点转换到世界空间下
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);//模型法线转换到世界空间下  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);//模型切线转换到世界空间下  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;//计算副切线 
				//构建切线到世界的变换矩阵
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
				
				TRANSFER_SHADOW(o);//计算shadow值
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);//节省了寄存器,从矩阵的第四行取模型顶点的世界坐标
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));//光线方向
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));//视角方向
				
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));//采样normal纹理
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));//变换到世界空间下
				//bump = mul(float3x3(i.TtoW0.xyz,i.TtoW1.xyz,i.TtoW2.xyz),bump);
				//至此 光方向 视角方向 法线方向都有了 就可以计算光照了
				
				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;//采样纹理 代替漫反射材质计算
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//环境光
			
			 	fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));//漫反射
				
				UNITY_LIGHT_ATTENUATION(atten, i, worldPos);//用宏来计算光照衰减和采样阴影，俩者相乘返给atten
				
				return fixed4(ambient + diffuse * atten, 1.0);
			}
			
			ENDCG
		}
		
		Pass { 
			Tags { "LightMode"="ForwardAdd" }
			
			Blend One One
		
			CGPROGRAM
			
			#pragma multi_compile_fwdadd
			// Use the line below to add shadows for point and spot lights
//			#pragma multi_compile_fwdadd_fullshadows
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;  
				float4 TtoW1 : TEXCOORD2;  
				float4 TtoW2 : TEXCOORD3;
				SHADOW_COORDS(4)
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
				
				TRANSFER_SHADOW(o);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				
				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;
				
			 	fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));
				
				UNITY_LIGHT_ATTENUATION(atten, i, worldPos);
				
				return fixed4(diffuse * atten, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Diffuse"
}
