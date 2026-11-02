package com.comodeu.service;

import com.comodeu.entity.ComoItem;
import com.comodeu.repository.ComoItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class ComoItemService {

    private final ComoItemRepository comoItemRepository;

    /**
     * Inicializa os 17 itens COMO D'EU no banco de dados
     */
    public void initializeComoItems() {
        if (comoItemRepository.count() > 0) {
            return;  // Já inicializado
        }

        // Categoria 1: Acessibilidade & Conforto
        saveItem(1, "Acessibilidade Física", "Rampas, escadas, portas, circulação, elevadores e acessibilidade geral para pessoas com mobilidade reduzida", "Acessibilidade", "rampa,escada,porta,acesso,acessível,elevador,desnível");
        saveItem(2, "Conforto Térmico", "Temperatura ambiente adequada, ventilação e climatização", "Conforto", "temperatura,frio,quente,clima,ventilação");
        saveItem(3, "Conforto Acústico", "Controle de ruído, reverberação, som ambiente e acústica do espaço", "Conforto", "barulho,som,ruído,acústica,silêncio");
        saveItem(4, "Qualidade da Iluminação", "Brilho adequado, uniformidade, ausência de ofuscamento e permitir visualização clara das obras", "Conforto", "luz,iluminação,escuro,brilho,claro,ofuscamento");
        saveItem(5, "Mobiliário Apropriado", "Bancos, assentos, espaços de descanso em quantidade e qualidade adequada", "Conforto", "banco,cadeira,assento,descanso,mobiliário");

        // Categoria 2: Informação & Comunicação
        saveItem(6, "Sinalização Clara", "Indicadores de direção, localização, mapa do espaço e orientação clara para visitantes", "Informação", "placa,sinal,indicação,direção,localizar,mapa");
        saveItem(7, "Informações Legíveis", "Tamanho de fonte, contraste, tipografia e legibilidade adequados", "Informação", "letra,fonte,pequena,contraste,legível,ilegível,wcag");
        saveItem(8, "Acesso à Informação", "Placas informativas, guias, folhetos, audioguias e recursos informativos disponíveis", "Informação", "informação,guia,folheto,audioguia,descrição");
        saveItem(9, "Comodidades Gerais", "Banheiros, fontes de água, café, loja, guarda-volumes e outros serviços essenciais", "Informação", "banheiro,água,café,loja,guarda-volumes,serviço");

        // Categoria 3: Experiência & Engajamento
        saveItem(10, "Clareza Expositiva", "Explicações claras sobre as obras, contexto histórico, significado e relevância", "Experiência", "explicação,contexto,história,significado,interpretação");
        saveItem(11, "Engajamento do Visitante", "Capacidade de manter interesse, evitar filas excessivas, ritmo apropriado de visita", "Experiência", "fila,espera,longa,congestionado,aglomeração,engajamento");
        saveItem(12, "Diversidade de Conteúdo", "Variedade de perspectivas, temáticas e conteúdo que represente múltiplas visões", "Experiência", "conteúdo,diversidade,perspectiva,variedade");

        // Categoria 4: Segurança & Recursos
        saveItem(13, "Segurança e Privacidade", "Medidas de segurança, proteção de dados, bem-estar e proteção do visitante", "Segurança", "segurança,risco,privacidade,proteção");
        saveItem(14, "Gestão do Tempo", "Duração adequada da visita, ritmo apropriado, não muito longa nem muito breve", "Segurança", "tempo,pressa,rápido,longo,duração");
        saveItem(15, "Qualidade do Atendimento", "Profissionalismo do staff, cortesia, conhecimento e disposição em ajudar", "Segurança", "atendimento,staff,guia,funcionário,profissional");
        saveItem(16, "Recursos Educacionais", "Materiais educacionais, atividades, workshops, programação e aprendizado", "Segurança", "educação,aprendizado,material,workshop,atividade");
        saveItem(17, "Impressão Geral / Satisfação", "Avaliação geral da experiência, satisfação do visitante e recomendação", "Segurança", "satisfação,impressão,geral,recomendação");
    }

    private void saveItem(Integer number, String name, String description, String category, String keywords) {
        ComoItem item = ComoItem.builder()
                .itemNumber(number)
                .name(name)
                .description(description)
                .category(category)
                .keywords(keywords)
                .active(true)
                .build();

        comoItemRepository.save(item);
    }

    public List<ComoItem> getAllItems() {
        return comoItemRepository.findAll();
    }

    public ComoItem getItem(Long id) {
        return comoItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Item COMO D'EU não encontrado: " + id));
    }

    public List<ComoItem> getItemsByCategory(String category) {
        return comoItemRepository.findByCategory(category);
    }
}
