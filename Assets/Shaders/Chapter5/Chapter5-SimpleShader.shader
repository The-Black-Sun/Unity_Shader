// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 5/Simple Shader" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
	}
	SubShader {
        Pass {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            uniform fixed4 _Color;
            
            //使用一个结构体定义顶点着色器的输入
			struct a2v {
                //使用模型空间的顶点坐标填充vertex变量
                float4 vertex : POSITION;
                //使用模型空间的法线方向填充normal变量
				float3 normal : NORMAL;
                //使用模型的第一套纹理坐标填充texcoord变量
				float4 texcoord : TEXCOORD0;
            };
            
            //使用结构体定义顶点着色器的输出
            struct v2f {
                //SV_POSITION定义表示Pos中包含了剪裁空间中的位置信息
                float4 pos : SV_POSITION;
                //COLOR0定义表示color存储了颜色信息
                fixed3 color : COLOR0;
            };
            
            v2f vert(a2v v) {
                //声明输出为结构体v2f
            	v2f o;
            	o.pos = UnityObjectToClipPos(v.vertex);
                //v.normal 包含顶点的法线方向，范围在[-1,1]
                //将法线分量范围映射到[0,1]中
                //存储到o.color中并传递给片元着色器
            	o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
            	fixed3 c = i.color;
                //使用_Color属性来控制输出颜色
            	c *= _Color.rgb;
                //将插值后的color显示到屏幕上
                return fixed4(c, 1.0);
            }

            ENDCG
        }
    }
}
