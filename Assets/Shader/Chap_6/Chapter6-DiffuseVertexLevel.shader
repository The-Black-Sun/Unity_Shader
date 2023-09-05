// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 6/Diffuse Vertex-Level"
{
    Properties{
        //漫反射颜色
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

            //定义输出输入结构体
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
                //顶点从模型空间转换到剪裁空间中；UNITY_MATRIX_MVP=>模型*世界*投影矩阵
                o.pos = UnityObjectToClipPos(v.vertex);
                
                //获取环境光，UNITY_LIGHTMODEL_AMBIENT
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //在世界空间计算，mul，点乘，将模型顶点的法线与世界矩阵相乘，获取世界空间的顶点法线；
                //_World2Object 模型空间到世界空间的变换矩阵的逆矩阵，调换在mul中的位置，得到与转置矩阵相同的矩阵乘法
                //normalize 归一化
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

                //获得环境光的光源方向
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                //漫反射=环境光*表面漫反射颜色*世界法线与世界入射光夹角的余弦值（小于0，则取0）
                //saturate 截取[0,1]
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                //光照效果=环境光+漫反射
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
