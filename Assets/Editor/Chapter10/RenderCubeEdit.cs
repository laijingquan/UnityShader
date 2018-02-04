using UnityEngine;
using System.Collections;
using UnityEditor;

public class RenderCubeEdit : EditorWindow {


    [MenuItem("Window/渲染场景到CubeMap")]
    static void Excute()
    {
        GetWindow(typeof(RenderCubeEdit),false,"CubeMap制作");
    }

    public Transform renderFromPosition;
    public Cubemap cubemap;
    public GameObject Target;
    void OnGUI()
    {

        GUILayout.Label("CubeMap");

        var target = (Cubemap)EditorGUILayout.ObjectField(cubemap, typeof(Cubemap), false);
        if(target!=cubemap)
        {
            cubemap = target;
        }

        GUILayout.Label("Transform");
        var transf = (Transform)EditorGUILayout.ObjectField(renderFromPosition, typeof(Transform));
        if (transf != renderFromPosition)
        {
            renderFromPosition = transf;
        }

        if (GUILayout.Button("渲染CubeMap")&&cubemap!=null&& renderFromPosition!=null)
        {
            GameObject go = new GameObject("CubemapCamera");
            go.AddComponent<Camera>();
            go.transform.position = renderFromPosition.position;
            go.GetComponent<Camera>().RenderToCubemap(cubemap);
            Target = go;
        }

        if(GUILayout.Button("删除Target")&& Target!=null)
        {
            DestroyImmediate(Target);
        }
    }
    
}
