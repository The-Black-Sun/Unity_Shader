// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 11/Billboard" {
	Properties {
		//广告牌技术的透明纹理
		_MainTex ("Main Tex", 2D) = "white" {}
		//整体颜色显示
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		//用于调整是固定法线还是指定向上的方向
		_VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1 
	}
	SubShader {
		//需要设置透明效果标签，取消批处理（模型空间顶点动画）
		//批处理会合并所有相关模型，会导致自身的模型空间丢失，无法在顶点着色器中完成顶点动画计算
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		
		Pass { 
			Tags { "LightMode"="ForwardBase" }
			//关深度，开混合，关剔除
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			fixed _VerticalBillboarding;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				//设置模型空间的原点座位广告牌的描点，使用内置变量获取模型空间下的视角位置
				float3 center = float3(0, 0, 0);
				float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos, 1));
				
				//根据观察位置和描点计算法线方向
				float3 normalDir = viewer - center;

				//通过_VerticalBillboarding属性控制垂直方向上的约束度
				//_VerticalBillboarding为1时，意味着法线方向固定为视角方向
				//为0时，意味着向上方向固定为（0,1,0）
				//单位化，得到方向矢量
				normalDir.y =normalDir.y * _VerticalBillboarding;
				normalDir = normalize(normalDir);

				
				//为了防止法线方向和向上方向平行，对y分量进行判断，得到适合的向上方向
				//根据法线方向和粗略的向上方向得到向右方向（叉乘，右方向垂直与前两者），并对结果进行归一化
				//通过右方向与法线方向得到上方向（叉乘，上方向垂直于前两者）
				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
				float3 rightDir = normalize(cross(upDir, normalDir));
				upDir = normalize(cross(normalDir, rightDir));
				
				//计算原始位置相对于锚点的偏移量
				float3 centerOffs = v.vertex.xyz - center;
				//根据三个偏移量以及三个正交基矢量计算新的顶点位置
				float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
              
				//模型空间顶点变换到剪裁空间中
				o.pos = UnityObjectToClipPos(float4(localPos, 1));
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

				return o;
			}
			
			//片元着色器进行纹理采样以及颜色计算
			fixed4 frag (v2f i) : SV_Target {
				fixed4 c = tex2D (_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				
				return c;
			}
			
			ENDCG
		}
	} 
	FallBack "Transparent/VertexLit"
}
