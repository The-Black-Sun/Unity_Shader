// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 12/Gaussian Blur" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		//高斯模糊程度，控制不同迭代之间高斯模糊的模糊区域范围
		_BlurSize ("Blur Size", Float) = 1.0
	}
	SubShader {
			//区别与CGPROGRAM，内部定义的代码不包含在任何Pass语义块中，但是在Pass
			//中可以直接引用调用，这是因为两个Pass中的代码完全相同，可以减少编写流程
			//起到类似于头文件的功能
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		//_MainTex_TexelSize变量，用来计算相邻像素的坐标偏移量
		sampler2D _MainTex;  
		half4 _MainTex_TexelSize;
		float _BlurSize;
		
		//5*5的二维高斯核可以拆成两个大小为5的一维高斯核，所以只需要计算5个纹理坐标即可
		//定义一个5维的纹理坐标数组
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv[5]: TEXCOORD0;
		};
		  
		//顶点着色器（竖直方向计算）
		v2f vertBlurVertical(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			half2 uv = v.texcoord;
			//利用5*5的二维高斯核对原图像进行高斯模糊
			//第一个坐标存储当前的采样纹理
			o.uv[0] = uv;
			//剩下的四个坐标则是高斯模糊中对邻域采样时使用的纹理坐标
			//通过与_BlurSize相乘控制采样距离，数值越大越模糊
			//把计算采样纹理的代码从片元着色器转移到顶点着色器中，可以减少运算，提高性能
			o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
			o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
					 
			return o;
		}
		//顶点着色器（水平方向计算）
		v2f vertBlurHorizontal(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			half2 uv = v.texcoord;
			
			o.uv[0] = uv;
			o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
			o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
					 
			return o;
		}
		
		//定义两个Pass公用的片元着色器
		fixed4 fragBlur(v2f i) : SV_Target {
			//由于拆成的2个一维高斯核，以及对称的关系，只需要记录3个高斯权重即可
			float weight[3] = {0.4026, 0.2442, 0.0545};
			
			//将sum初始化为当前的像素值乘以权重值
			fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
			
			//根据对称性，进行2次迭代，包含了两次纹理采样
			//将像素值与权重相乘之后的结果叠加到sum中，最后函数返回滤波结果
			for (int it = 1; it < 3; it++) {
				sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
				sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
			}
			
			return fixed4(sum, 1.0);
		}
		    
		ENDCG
		
			//保持深度测试，关闭剔除，关闭深度写入
		ZTest Always Cull Off ZWrite Off
		
			//在两个pass中通过NAME语义定义名称，之后分别调用对应的顶点着色器以及片元着色器。
			//定义名字可以在其他Shader中直接通过名字来使用该Pass，而不要重复编写代码
		Pass {
			NAME "GAUSSIAN_BLUR_VERTICAL"
			
			CGPROGRAM
			  
			#pragma vertex vertBlurVertical  
			#pragma fragment fragBlur
			  
			ENDCG  
		}
		
		Pass {  
			NAME "GAUSSIAN_BLUR_HORIZONTAL"
			
			CGPROGRAM  
			
			#pragma vertex vertBlurHorizontal  
			#pragma fragment fragBlur
			
			ENDCG
		}
	} 
	FallBack "Diffuse"
}
