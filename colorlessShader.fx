cbuffer cbPerObject : register(b0) 
{
    float4x4 worldMatrix    : WORLD; //these are keywords assigned from the CPU side as I understand it
    float4x4 worldViewProjectionMatrix : WORLDVIEWPROJECTION;
    float4x4 viewMatrix : VIEW;
    float4x4 projection : PROJECTION;
};

RasterizerState OutlineRS
{
    CullMode = Back;
};

RasterizerState RegularRS
{
    CullMode = None;
};

DepthStencilState myDS
{
    DepthEnable = true;
    DepthWriteMask = ALL;
    DepthFunc = LESS_EQUAL;
};

// UI OPTIONS
int black
<
    string UIGroup = "Settings";
    string UIName = "Color";
    string UIFieldNames = "Black:White";

    float UIMin = 0;
    float UIMax = 1;
    float UIStep = 1;
> = 0;

float depthSelect
<
    string UIGroup = "Settings";
    string UIName = "Depth Effect";
    float UIMin = 1.0f;
    float UIMax = 10.0f;
> = 0.0f;

float lineThickness
<
    string UIGroup = "Settings";
    string UIName = "Line Thickness";
    float UIMin = 0.0f;
    float UIMax = 10.0f;
> = 0.1f;

// STRUCTS
struct VertexInput
{
    float4 position : POSITION;
    float3 normal : NORMAL;
    float3 binormal : BINORMAL;
    float3 tangent : TANGENT;
    float4 color : COLOR;
};

struct VertexOutput
{
    float3 normal : NORMAL;
    float4 position : SV_POSITION;
    float4 color : COLOR;
};


// ACTUAL SHADERS
VertexOutput outerV(VertexInput input)
{
    VertexOutput output;

    float4 vColor = !black ? float4(0.0f, 0.0f, 0.0f, 1.0f) : float4(1.0f, 1.0f, 1.0f, 1.0f);

    input.position.xyz += input.normal * + (2 * lineThickness); //this requires the vertice's normals to be averaged between adjacent vertices (in maya, MESH DISPLAY > SOFTEN EDGES)

    output.position = mul(input.position, worldViewProjectionMatrix);
    output.color = vColor;
    output.normal = input.normal;//mul(input.normal, worldViewProjectionMatrix);

    return output;
}

VertexOutput innerV(VertexInput input)
{
    VertexOutput output;

    float4 vColor = !black ? float4(1.0f, 1.0f, 1.0f, 1.0f) : float4(0.0f, 0.0f, 0.0f, 1.0f);

    input.position.xyz += input.normal * lineThickness; //this requires the vertice's normals to be averaged between adjacent vertices (in maya, MESH DISPLAY > SOFTEN EDGES)

    output.position = mul(input.position, worldViewProjectionMatrix);
    output.color = vColor;
    output.normal = input.normal;

    return output;
}

VertexOutput v(VertexInput input)
{
    VertexOutput output;

    float4 vColor = !black ? float4(0.0f, 0.0f, 0.0f, 1.0f) : float4(1.0f, 1.0f, 1.0f, 1.0f);

    output.position = mul(input.position, worldViewProjectionMatrix);
    output.color = vColor;
    output.normal = input.normal;

    return output;
}

VertexOutput v2(VertexInput input)
{
    VertexOutput output;

    float3 upVec = float3(viewMatrix._21, viewMatrix._22, viewMatrix._23);
    float3 lookVec = float3(viewMatrix._31, viewMatrix._32, viewMatrix._33);

    //input.position 

    float4 finalPos = mul(input.position, worldViewProjectionMatrix);

    finalPos.xy *= 1.5f; //simple scale

    output.position = finalPos;//mul(input.position, worldViewProjectionMatrix);
    output.color = float4(upVec, 1.0f);
    output.normal = input.normal;

    return output;
}

float4 f(VertexOutput input) : COLOR
{
    float4 outputColor = input.color;
    return outputColor;
}

float4 f2(VertexOutput input) : COLOR
{
    float4 outputColor = float4(abs(input.normal.x), abs(input.normal.y), abs(input.normal.z), 1.0f);
    return outputColor;
}

[maxvertexcount(3)]
void g(triangle VertexOutput input[3], inout TriangleStream<VertexOutput> triStream)
{
    for(int i = 0; i < 3; i++)
    {
        VertexOutput output = (VertexOutput)0;

        float3 pogPog = input[i].position.xyz + input[i].normal * 0.1f;

        output.position = float4(pogPog, input[i].position.w);
        output.color = input[i].color;

        triStream.Append(output);
    }

    triStream.RestartStrip();
}


// TECHNIQUES
technique11 Flat
{
    pass p0 //object
    {
        SetVertexShader(CompileShader(vs_5_0, v()));
        SetPixelShader(CompileShader(ps_5_0, f()));
    }
}

technique11 Single
{
    pass p0 //object
    {
        SetVertexShader(CompileShader(vs_5_0, v()));
        SetPixelShader(CompileShader(ps_5_0, f()));
    }
    pass p1 // inner outline
    {
        SetVertexShader(CompileShader(vs_5_0, innerV()));
        SetPixelShader(CompileShader(ps_5_0, f()));

        SetRasterizerState(OutlineRS);
    }
}

technique11 Double
{
    pass p0 //outer outline
    {
        SetVertexShader(CompileShader(vs_5_0, outerV()));
        SetPixelShader(CompileShader(ps_5_0, f()));
        
        //pContext->OMSetDepthStencilState(myDS, 1);

        SetRasterizerState(OutlineRS);
    }
    pass p1 // inner outline
    {
        SetVertexShader(CompileShader(vs_5_0, innerV()));
        SetPixelShader(CompileShader(ps_5_0, f()));

        SetRasterizerState(OutlineRS);
    }
    pass p2 // object
    {
        SetVertexShader(CompileShader(vs_5_0, v()));
        SetPixelShader(CompileShader(ps_5_0, f()));

        SetRasterizerState(RegularRS);
    }
}

technique11 Experimental
{   
    pass p0
    {
        SetVertexShader(CompileShader(vs_5_0, v2()));

        SetGeometryShader(CompileShader(gs_5_0, g()));

        SetPixelShader(CompileShader(ps_5_0, f()));

        
        SetRasterizerState(RegularRS);
    }
}