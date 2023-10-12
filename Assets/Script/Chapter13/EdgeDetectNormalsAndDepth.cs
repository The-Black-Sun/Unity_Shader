using UnityEngine;
using System.Collections;

public class EdgeDetectNormalsAndDepth : PostEffectsBase {

	public Shader edgeDetectShader;
	private Material edgeDetectMaterial = null;
	public Material material {  
		get {
			edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
			return edgeDetectMaterial;
		}  
	}

	//属性设置，边缘线强度
	[Range(0.0f, 1.0f)]
	public float edgesOnly = 0.0f;
	//描边颜色
	public Color edgeColor = Color.black;
	//背景颜色
	public Color backgroundColor = Color.white;
	//采样距离，越大，描边越宽
	public float sampleDistance = 1.0f;
	//深度灵敏度，影响深度值差距
	public float sensitivityDepth = 1.0f;
	//法线灵敏度，影响法线差距
	public float sensitivityNormals = 1.0f;
	
	//获取深度法线纹理
	void OnEnable() {
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
	}

	[ImageEffectOpaque]
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		//将参数传递给Shader
		if (material != null) {
			material.SetFloat("_EdgeOnly", edgesOnly);
			material.SetColor("_EdgeColor", edgeColor);
			material.SetColor("_BackgroundColor", backgroundColor);
			material.SetFloat("_SampleDistance", sampleDistance);
			material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0.0f, 0.0f));

			Graphics.Blit(src, dest, material);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
