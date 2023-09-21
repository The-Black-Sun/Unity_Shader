// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 11/Image Sequence Animation" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		//包含所有关键帧图像的纹理
		_MainTex ("Image Sequence", 2D) = "white" {}
		//水平方向和竖直方向包含的关键帧图像个数
    	_HorizontalAmount ("Horizontal Amount", Float) = 4
    	_VerticalAmount ("Vertical Amount", Float) = 4
		//控制序列帧动画的播放速度
    	_Speed ("Speed", Range(1, 100)) = 30
	}
	SubShader {
		//序列帧图像通常包含透明通道，这里作为一个半透明对象。
		//使用半透明“标配”设置标签
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			//关闭深度写入
			//开启混合模式
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
			
			#pragma vertex vert  
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			//属性变量
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _HorizontalAmount;
			float _VerticalAmount;
			float _Speed;
			
			struct a2v {  
			    float4 vertex : POSITION; 
			    float2 texcoord : TEXCOORD0;
			};  
			
			struct v2f {  
			    float4 pos : SV_POSITION;
			    float2 uv : TEXCOORD0;
			};  
			
			//顶点着色器进行基本的顶点交换，并将顶点纹理存储到结构体中
			v2f vert (a2v v) {  
				v2f o;  
				o.pos = UnityObjectToClipPos(v.vertex);  
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);  
				return o;
			}  

			fixed4 frag (v2f i) : SV_Target {
				//计算关键帧的行列索引
				//_Time.y是自场景加载之后经过的时间，和速度属性相乘得到模拟时间，通过CG的Floor函数取整
				float time = floor(_Time.y * _Speed);  
				float row = floor(time / _HorizontalAmount);
				float column = time - row * _HorizontalAmount;
				
				//将原纹理坐标i.uv按照行数和列数进行等分获取每个子图像的纹理坐标范围
//				half2 uv = float2(i.uv.x /_HorizontalAmount, i.uv.y / _VerticalAmount);
 				//根据当前行列对纹理坐标结果进行偏移（竖直方向偏移用减法，因为Unity中纹理坐标竖直方向的顺序是从下到上增大。与序列帧纹理中顺序，播放从上到下是相反的）
//				uv.x += column / _HorizontalAmount;
//				uv.y -= row / _VerticalAmount;
				
				half2 uv = i.uv + half2(column, -row);
				uv.x /=  _HorizontalAmount;
				uv.y /= _VerticalAmount;
				
				//进行威力采样
				fixed4 c = tex2D(_MainTex, uv);
				c.rgb *= _Color;
				
				return c;
			}
			
			ENDCG
		}  
	}
	FallBack "Transparent/VertexLit"
}
