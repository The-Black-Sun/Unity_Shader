// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 10/Glass Refraction" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
		//法线纹理
		_BumpMap ("Normal Map", 2D) = "bump" {}
		//环境纹理——通过环境映射渲染进纹理
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}
		//控制模拟折射的图像扭曲程度
		_Distortion ("Distortion", Range(0, 100)) = 10
		//用来控制折射程度（0反射，1折射）
		_RefractAmount ("Refract Amount", Range(0.0, 1.0)) = 1.0
	}
	SubShader {
		//设置透明渲染队列，保证在不透明物体之后渲染
		//设置RenderType，使用着色器替换时，物体能够被正确渲染（第13章）
		Tags { "Queue"="Transparent" "RenderType"="Opaque" }
		
		/*
		* 设置GrabPass，定义一个抓取屏幕图像的Pass，这个Pass中定义了个字符串
		* 字符串名称是抓取的屏幕会被渲染进哪一个纹理
		*/
		GrabPass { "_RefractionTex" }
		
		//定义玻璃渲染的Pass，在Shader中访问各个属性
		Pass {		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _BumpMap;
			float4 _BumpMap_ST;

			//立方体环境纹理
			samplerCUBE _Cubemap;
			//折射图像扭曲程度
			float _Distortion;
			//控制折射程度
			fixed _RefractAmount;

			//GrabPass中指定的纹理名称
			sampler2D _RefractionTex;
			//获取纹理的纹素大小
			float4 _RefractionTex_TexelSize;
			
			//顶点、法线、切线、纹理
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float2 texcoord: TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				//切线空间到世界空间的变换矩阵
				float4 TtoW0 : TEXCOORD2;  
			    float4 TtoW1 : TEXCOORD3;  
			    float4 TtoW2 : TEXCOORD4; 
			};
			
			//顶点着色器
			v2f vert (a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				//通过内置的ComputeGrabScreenPos函数，获取对应被抓取的屏幕图像的采样坐标
				o.scrPos = ComputeGrabScreenPos(o.pos);
				
				//计算_MainTex以及_BumpMap的采样坐标（主纹理与法线）
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
				
				//获取世界空间的顶点、（切线空间的三条轴）法线、切线以及副切线
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				//获得切线空间到世界空间的转换坐标
				//切线空间到世界空间的转换坐标，就是世界空间的三条切线空间的坐标轴排列组成。其他转换矩阵同理可求
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				//获取顶点的世界空间坐标
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				//获取世界空间的视角方向
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				//进行法线纹理采样
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));	
				
				//使用法线以及_Distortion折射扭曲程度以及纹理纹素大小计算偏移值
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				//计算屏幕纹理坐标
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				//通过屏幕纹理坐标进行折射纹理采样，对scrPos透视除法得到真正的屏幕坐标（原理：4.9.3）
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
				
				//获取世界空间发法线（转换矩阵计算）
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				//视角方向计算相对于法线的反射方向
				fixed3 reflDir = reflect(-worldViewDir, bump);
				//对主纹理进行采样，得到主纹理颜色
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				//使用反射方向对立方体纹理进行采样，将结果与主纹理颜色相乘得到反射颜色
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;
				
				//通过菲涅尔近似公式计算最终颜色
				fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;
				
				return fixed4(finalColor, 1);
			}
			
			ENDCG
		}
	}
	
	FallBack "Diffuse"
}
