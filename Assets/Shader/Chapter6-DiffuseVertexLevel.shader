// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 6/Diffuse Vertex-Level"
{
    Properties{
        //��������ɫ
        _Diffuse("Diffuse",color) = (1,1,1,1)
    }

    SubShader{
       Pass{
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include"Lighting.cginc"

            fixed4 _Diffuse;

            //�����������ṹ��
            struct a2v {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
            };

            struct v2f {
                float4 pos:SV_POSITION;
                fixed3 color : COLOR;
            };
            
            v2f vert(a2v v) {
                v2f o;
                //�����ģ�Ϳռ�ת�������ÿռ��У�UNITY_MATRIX_MVP=>ģ��*����*ͶӰ����
                o.pos = UnityObjectToClipPos(v.vertex);
                
                //��ȡ�����⣬UNITY_LIGHTMODEL_AMBIENT
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //������ռ���㣬mul����ˣ���ģ�Ͷ���ķ��������������ˣ���ȡ����ռ�Ķ��㷨�ߣ�
                //_World2Object ģ�Ϳռ䵽����ռ�ı任���������󣬵�����mul�е�λ�ã��õ���ת�þ�����ͬ�ľ���˷�
                //normalize ��һ��
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

                //��û�����Ĺ�Դ����
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                //������=������*������������ɫ*���編�������������нǵ�����ֵ��С��0����ȡ0��
                //saturate ��ȡ[0,1]
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                //����Ч��=������+������
                o.color = ambient + diffuse;

                return o;
            }

            fixed4 frag(v2f i) :SV_Target{
                return fixed4(i.color,1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
