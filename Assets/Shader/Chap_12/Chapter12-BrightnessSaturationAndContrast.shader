// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 12/Brightness Saturation And Contrast" {
	Properties {
		//声明要进行使用的属性：纹理、亮度、饱和度、对比度
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Brightness ("Brightness", Float) = 1
		_Saturation("Saturation", Float) = 1
		_Contrast("Contrast", Float) = 1
	}
	SubShader {
		Pass {  
			//屏幕后处理实际上是场景中绘制了一个与屏幕同宽同高的四边形，为了防止对其他物体产生影响，需要设置相关的渲染状态
			//关闭深度写入，如果OnRenderImage函数在不透明的Pass中执行完后被立即调用，不关闭深度写入会影响透明Pass的渲染
			ZTest Always Cull Off ZWrite Off
			
			CGPROGRAM  
			#pragma vertex vert  
			#pragma fragment frag  
			  
			#include "UnityCG.cginc"  
			  
			//纹理与属性
			sampler2D _MainTex;  
			half _Brightness;
			half _Saturation;
			half _Contrast;
			  
			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv: TEXCOORD0;
			};
			 
			//顶点着色器，进行顶点变换，并将纹理坐标传递给片元着色器
			v2f vert(appdata_img v) {
				v2f o;
				
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.uv = v.texcoord;
						 
				return o;
			}
			
			//片元着色器，实现用于调整亮度、饱和度、对比度
			fixed4 frag(v2f i) : SV_Target {
				fixed4 renderTex = tex2D(_MainTex, i.uv);  
				  
				//亮度，直接与颜色相乘
				fixed3 finalColor = renderTex.rgb * _Brightness;
				
				//使用亮度颜色创建饱和度为0的颜色值，并使用_Saturation属性在其和上一步得到的颜色之间进行插值
				fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
				fixed3 luminanceColor = fixed3(luminance, luminance, luminance);
				finalColor = lerp(luminanceColor, finalColor, _Saturation);
				
				//创建对比度为0的颜色值（各分量为0.5），使用_Contrast属性在其和上一步得到的颜色之间进行插值
				fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
				finalColor = lerp(avgColor, finalColor, _Contrast);
				
				return fixed4(finalColor, renderTex.a);  
			}  
			  
			ENDCG
		}  
	}
	
	Fallback Off
}
