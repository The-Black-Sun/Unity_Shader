// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 11/Water" {
	Properties {
		//��������
		_MainTex ("Main Tex", 2D) = "white" {}
		//����������ɫ
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		//����ˮ����������
		_Magnitude ("Distortion Magnitude", Float) = 1
		//���Ʋ���Ƶ��
 		_Frequency ("Distortion Frequency", Float) = 1
		//���Ʋ����ĵ���
 		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10
		//���ƺ���������ƶ��ٶ�
 		_Speed ("Speed", Float) = 0.5
	}
	SubShader {
		// DisableBatchingָ���Ƿ�ȡ���Ը�shaderʹ��������
		// ��Ҫ���⴦���Shaderͨ���ǰ�����ģ�Ϳռ�Ķ��㶯����shader���������ϲ�������ص�ģ�ͣ�����ģ�͸��Ե�ģ�Ϳռ䶪ʧ
		// ��Ҫ�������ģ�Ϳռ��¶�һ�������ƫ�ƣ���������ȡ�������������
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			//�ر����д�룬�������û��ģʽ���ر��޳�����
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
			
			CGPROGRAM  
			#pragma vertex vert 
			#pragma fragment frag
			
			#include "UnityCG.cginc" 
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			float _Magnitude;
			float _Frequency;
			float _InvWaveLength;
			float _Speed;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			//������ɫ�����ö��㶯��
			v2f vert(a2v v) {
				v2f o;
				
				//���㶥��λ������ֻ�Զ���x�������λ��
				float4 offset;
				//yzw��λ��������Ϊ0
				offset.yzw = float3(0.0, 0.0, 0.0);
				//����x��λ����
				offset.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
				//��ñ任��Ķ���λ��
				o.pos = UnityObjectToClipPos(v.vertex + offset);
				
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv +=  float2(0.0, _Time.y * _Speed);
				
				return o;
			}
			
			//ƬԪ��ɫ����������в�����������ɫ����
			fixed4 frag(v2f i) : SV_Target {
				fixed4 c = tex2D(_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				
				return c;
			} 
			
			ENDCG
		}
	}
	FallBack "Transparent/VertexLit"
}
