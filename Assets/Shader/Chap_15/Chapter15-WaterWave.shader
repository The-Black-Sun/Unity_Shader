// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 15/Water Wave" {
	Properties {
		//物体颜色
		_Color ("Main Color", Color) = (0, 0.15, 0.115, 1)
		//主纹理
		_MainTex ("Base (RGB)", 2D) = "white" {}
		//水波纹理——噪声纹理
		_WaveMap ("Wave Map", 2D) = "bump" {}
		//立方体纹理
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}
		//水波移动xy方向速度
		_WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01
		_WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01
		//控制模拟折射时图像的扭曲程度
		_Distortion ("Distortion", Range(0, 100)) = 10
	}
	SubShader {
		//设置渲染队列，设置RenderType为了着色器替换时，物体能够被正确渲染（通常在需要得到摄像机的深度与法线纹理的时候使用，13章）
		Tags { "Queue"="Transparent" "RenderType"="Opaque" }
		//GrabPass截取屏幕图像，抓取的纹理命名为_RefractionTex
		GrabPass { "_RefractionTex" }
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			#pragma multi_compile_fwdbase
			
			#pragma vertex vert
			#pragma fragment frag
			//颜色与主纹理
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			//噪声纹理
			sampler2D _WaveMap;
			float4 _WaveMap_ST;
			//立方体纹理
			samplerCUBE _Cubemap;
			//水波xy位移速度
			fixed _WaveXSpeed;
			fixed _WaveYSpeed;
			//折射扭曲程度
			float _Distortion;
			//摄像机截取的纹理与偏移
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;  
				float4 TtoW1 : TEXCOORD3;  
				float4 TtoW2 : TEXCOORD4; 
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				//顶点转化到屏幕空间（得到对应被抓取的屏幕图像的采样坐标）
				o.scrPos = ComputeGrabScreenPos(o.pos);
				
				//计算采样坐标
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);
				
				//计算切线空间的副切线在世界空间的表示，并得到切线空间到世界空间的转化矩阵
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				//获得顶点世界坐标
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				//获得视角方向
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				//计算法线纹理（噪声纹理）的当前偏移量
				float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);
				
				//对噪声纹理进行采样
				fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb;
				fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb;
				fixed3 bump = normalize(bump1 + bump2);
				
				// 使用采样值与_Distortion以及屏幕空间偏移值对屏幕图像的纹理坐标进行偏移，模拟折射效果
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				// 与z坐标相乘，模拟深度越大，折射程度越大
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				//透视除法，并纹理采样
				fixed3 refrCol = tex2D( _RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
				
				// 将法线从切线空间变回世界空间
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				//纹理采样得到颜色
				fixed4 texColor = tex2D(_MainTex, i.uv.xy + speed);
				//得到视角方向相对于法线的反射方向
				fixed3 reflDir = reflect(-viewDir, bump);
				//使用反射方向进行环境纹理采样并与纹理颜色和物体颜色混合，得到反射颜色
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb * _Color.rgb;
				
				//计算菲涅尔系数
				fixed fresnel = pow(1 - saturate(dot(viewDir, bump)), 4);
				fixed3 finalColor = reflCol * fresnel + refrCol * (1 - fresnel);
				
				return fixed4(finalColor, 1);
			}
			
			ENDCG
		}
	}
	// Do not cast shadow
	FallBack Off
}
