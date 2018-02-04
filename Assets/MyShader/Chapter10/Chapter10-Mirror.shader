﻿Shader "MyShader/Chapter10/Mirror" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
	}
	SubShader {
		Tags{"RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			sampler2D _MainTex;

			struct a2v{
				float4 vertex:POSITION;
				float3 texcoord:TEXCOORD0;
			};
			struct v2f{
				float4 pos:SV_POSITION;
				float2 uv:TEXCOORD;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				o.uv = v.texcoord;
				//镜子照出来的是左右翻转的
				o.uv.x=1-o.uv.x;
				return o;
			}
			fixed4 frag(v2f i):SV_Target{
				return tex2D(_MainTex,i.uv);
			}
			ENDCG
		}
	}
	FallBack Off
}
