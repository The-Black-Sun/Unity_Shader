// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 12/Bloom" {
	Properties {
		//输入的渲染纹理
		_MainTex ("Base (RGB)", 2D) = "white" {}
		//高斯模糊之后的较亮区域
		_Bloom ("Bloom (RGB)", 2D) = "black" {}
		//亮度阈值
		_LuminanceThreshold ("Luminance Threshold", Float) = 0.5
		//控制不同迭代之间高斯模糊的模糊区域范围
		_BlurSize ("Blur Size", Float) = 1.0
	}
	SubShader {
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		//_MainTex_TexelSize变量，用来计算相邻像素的坐标偏移量
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		//记录较亮区域纹理
		sampler2D _Bloom;
		float _LuminanceThreshold;
		float _BlurSize;
		
		struct v2f {
			float4 pos : SV_POSITION; 
			half2 uv : TEXCOORD0;
		};

		//提取较亮区域的顶点着色器
		v2f vertExtractBright(appdata_img v) {
			v2f o;
			
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
					 
			return o;
		}
		
		fixed luminance(fixed4 color) {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
		}

		//提取较亮区域的片元着色器
		fixed4 fragExtractBright(v2f i) : SV_Target {
			//对主纹理进行纹理采样获取颜色值
			fixed4 c = tex2D(_MainTex, i.uv);
			//将采样得到的亮度值减去阈值，并将结果截取到0~1之间
			fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);
			
			return c * val;
		}
		
		//定义混合亮部图像和原图像时使用的顶点着色器与片元着色器	
		struct v2fBloom {
			float4 pos : SV_POSITION; 
			half4 uv : TEXCOORD0;
		};
		
		v2fBloom vertBloom(appdata_img v) {
			v2fBloom o;
			
			//uv中定义了两个纹理坐标，
			//xy分量对应了_MainTex，即原图像的纹理坐标
			//zw分量对应了_Bloom，即模糊后较亮区域的纹理坐标
			o.pos = UnityObjectToClipPos (v.vertex);
			o.uv.xy = v.texcoord;
			o.uv.zw = v.texcoord;
			
			//需要对这个纹理坐标进行平台差异化处理（5.6.1）
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0.0)
				o.uv.w = 1.0 - o.uv.w;
			#endif
				        	
			return o; 
		}
		
		//将两张纹理的采样结果相加混合
		fixed4 fragBloom(v2fBloom i) : SV_Target {
			return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
		} 
		
		ENDCG
		
		ZTest Always Cull Off ZWrite Off
		
		//定义需要的四个Pass
		Pass {  
			CGPROGRAM  
			#pragma vertex vertExtractBright  
			#pragma fragment fragExtractBright  
			
			ENDCG  
		}
		
		UsePass "Unity Shaders Book/Chapter 12/Gaussian Blur/GAUSSIAN_BLUR_VERTICAL"
		
		UsePass "Unity Shaders Book/Chapter 12/Gaussian Blur/GAUSSIAN_BLUR_HORIZONTAL"
		
		Pass {  
			CGPROGRAM  
			#pragma vertex vertBloom  
			#pragma fragment fragBloom  
			
			ENDCG  
		}
	}
	FallBack Off
}
