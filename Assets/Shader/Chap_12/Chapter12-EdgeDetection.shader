// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 12/Edge Detection" {
	Properties {
		//截取的屏幕纹理，以及边缘线强度，描边颜色，以及背景颜色的参数
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_EdgeOnly ("Edge Only", Float) = 1.0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
	}
	SubShader {
		Pass {  
			ZTest Always Cull Off ZWrite Off
			
			CGPROGRAM
			
			#include "UnityCG.cginc"
			
			#pragma vertex vert  
			#pragma fragment fragSobel
			
			//新变量_MainTex_TexelSize，是unity提供的访问_MainTex纹理对应的每个纹素的大小
			//例如512*512的纹理，大小就为1/512
			sampler2D _MainTex;  
			uniform half4 _MainTex_TexelSize;
			fixed _EdgeOnly;
			fixed4 _EdgeColor;
			fixed4 _BackgroundColor;
			
			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv[9] : TEXCOORD0;
			};
			 
			//在顶点着色器中计算边缘检测需要的纹理坐标
			v2f vert(appdata_img v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				half2 uv = v.texcoord;
				//定义一个维数为9的纹理数组，对应使用Sobel算子采样时需要的9个相邻纹理坐标
				//通过把计算采样纹理坐标的代码从片元着色器转移到顶点着色器中，
				//注意这样的转移是由于从顶点着色器到片元着色器的插值是线性的，所以这样的转移并不会影响纹理坐标的计算结果
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);
						 
				return o;
			}
			
			fixed luminance(fixed4 color) {
				return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
			}
			
			//Sobel函数将利用Sobel算子对原图进行边缘检测、
			//首先确定水平方向以及竖直方向使用的卷积核Gx和Gy
			//依次对9个像素进行采样，计算亮度值，在于卷积核中对应权重相乘之后叠加到鸽子的梯度值上
			//最后从1中减去水平方向和竖直方向的梯度值的绝对值，的带edge
			//edge值越小，表明这个像素就越可能是个边缘点
			half Sobel(v2f i) {
				const half Gx[9] = {-1,  0,  1,
										-2,  0,  2,
										-1,  0,  1};
				const half Gy[9] = {-1, -2, -1,
										0,  0,  0,
										1,  2,  1};		
				
				half texColor;
				half edgeX = 0;
				half edgeY = 0;
				for (int it = 0; it < 9; it++) {
					texColor = luminance(tex2D(_MainTex, i.uv[it]));
					edgeX += texColor * Gx[it];
					edgeY += texColor * Gy[it];
				}
				
				half edge = 1 - abs(edgeX) - abs(edgeY);
				
				return edge;
			}
			
			//片元着色器
			fixed4 fragSobel(v2f i) : SV_Target {
				//首先调用Sobel函数计算当前像素的梯度值edge，并利用该值分别计算背景为原图和纯色下的颜色值
				//再利用_EdgeOnly在两者之间进行插值得到最终的像素值
				//Sobel函数将利用Sobel算子对原图进行边缘检测
				half edge = Sobel(i);
				
				fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);
				fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
				return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
 			}
			
			ENDCG
		} 
	}
			//关闭Shader回调
	FallBack Off
}
