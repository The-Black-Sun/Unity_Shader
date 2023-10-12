// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 13/Motion Blur With Depth Texture" {
	Properties {
		//纹理与模糊程度
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurSize ("Blur Size", Float) = 1.0
	}
	SubShader {
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		//纹理与对应主纹素大小偏移
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		//深度纹理，
		sampler2D _CameraDepthTexture;
		//逆矩阵（当前视角*投影的逆矩阵）
		float4x4 _CurrentViewProjectionInverseMatrix;
		//上一个视角*投影矩阵
		float4x4 _PreviousViewProjectionMatrix;
		//模糊程度
		half _BlurSize;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			//深度纹理的采样坐标
			half2 uv_depth : TEXCOORD1;
		};
		
		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;
			
			//平台差异化处理
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif
					 
			return o;
		}
		
		fixed4 frag(v2f i) : SV_Target {
			// 获取深度缓冲区的深度纹理，并采样得到深度值
			float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
			// 构建像素NDC坐标H，d*2-1（反映射）
			float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);
			// 使用当前帧的视角矩阵*投影矩阵的逆矩阵对NDC进行变化=>回到世界空间
			float4 D = mul(_CurrentViewProjectionInverseMatrix, H);
			// 除以w，得到世界空间坐标（）
			float4 worldPos = D / D.w;
			
			// 获得当前帧的DNC坐标
			float4 currentPos = H;
			// 使用世界空间坐标，和前一帧的视角投影矩阵对其进行变化，得到前一帧在NDC下的坐标
			float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
			// 同样除以w分量
			previousPos /= previousPos.w;
			
			// 计算前一帧和当前帧在屏幕空间下的位置差，得到像素速度
			float2 velocity = (currentPos.xy - previousPos.xy)/2.0f;
			
			//通过速度偏移纹理坐标，对邻域像素进行采样
			//之后取平均值得到模糊效果
			float2 uv = i.uv;
			float4 c = tex2D(_MainTex, uv);
			uv += velocity * _BlurSize;
			for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) {
				float4 currentColor = tex2D(_MainTex, uv);
				c += currentColor;
			}
			c /= 3;
			
			return fixed4(c.rgb, 1.0);
		}
		
		ENDCG
		
		//定义运动模糊所需要的Pass，并调用顶点片元着色器
		Pass {      
			ZTest Always Cull Off ZWrite Off
			    	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG  
		}
	} 
	FallBack Off
}
