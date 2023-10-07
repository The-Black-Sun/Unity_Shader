using UnityEngine;
using System.Collections;

//继承屏幕后处理效果基类
public class EdgeDetection : PostEffectsBase {

	//声明Shader文件、创建相对应的材质
	public Shader edgeDetectShader;
	private Material edgeDetectMaterial = null;
	public Material material {  
		get {
			edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
			return edgeDetectMaterial;
		}  
	}

	//边缘先强度、描边颜色、以及背景颜色参数
	[Range(0.0f, 1.0f)]
	public float edgesOnly = 0.0f;

	public Color edgeColor = Color.black;
	
	public Color backgroundColor = Color.white;

	//真正进行特效处理的函数
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		//对三个参数进行控制，并且传递进Shader中
		if (material != null) {
			material.SetFloat("_EdgeOnly", edgesOnly);
			material.SetColor("_EdgeColor", edgeColor);
			material.SetColor("_BackgroundColor", backgroundColor);

			Graphics.Blit(src, dest, material);
		} else {
			//材质不存在时，直接进行屏幕显示
			Graphics.Blit(src, dest);
		}
	}
}
